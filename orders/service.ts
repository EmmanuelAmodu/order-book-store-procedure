import { connection } from "../database/connection";
import { producer } from "../kafka";

export default class OrderService {
  constructor() {
    this.noticationLoop();
  }

  private noticationLoop () {
    if (process.env.INSTANCE_ID == "1") {
      setInterval(async () => {
        const lastUpdateTime = await this.fetchLastUpdateTimeNotificationSent();
  
        console.log("Sending order notification", "at", lastUpdateTime);
  
        const orders = await this.fetchOrders(lastUpdateTime);
        await this.sendOrderNotification(orders);
        await this.saveLastUpdateTimeToNotification(
          orders[orders.length - 1].updated_at
        );
  
        console.log(
          `Sent ${orders.length} order notifications`,
          "at",
          lastUpdateTime
        );
      }, 1000);
    }
  }

  private async fetchOrders(lastUpdateTime: Date): Promise<any[]> {
    return new Promise((resolve, reject) => {
      connection.query(
        "SELECT `id`, `status` FROM `orders` WHERE `updated_at` > ? Limit 1000",
        [lastUpdateTime],
        function (error, results, fields) {
          if (error) {
            reject(error);
          }
  
          resolve(results);
        }
      );
    });
  }
  
  private async saveLastUpdateTimeToNotification(lastUpdateTime: Date) {
    return new Promise((resolve, reject) => {
      connection.query(
        "INSERT INTO `notification` (`update_time_notification_sent`) VALUES (?)",
        [lastUpdateTime],
        function (error, results, fields) {
          if (error) {
            reject(error);
          }
  
          resolve(results);
        }
      );
    });
  }
  
  private async sendOrderNotification(orders: any[]) {
    await producer.send({
      topic: "order-notification",
      messages: orders.map((order) => ({ value: JSON.stringify(order) })),
    });
  }
  
  private async getPair(baseAsset: string, quoteAsset: string): Promise<any> {
    return new Promise((resolve, reject) => {
      connection.query(
        "SELECT * FROM `pairs` WHERE `base_asset` = ? AND `quote_asset` = ? LIMIT 1",
        [baseAsset, quoteAsset],
        function (error, results, fields) {
          if (error) {
            reject(error);
          }
  
          resolve(results[0]);
        }
      );
    });
  }
  
  private async getWallet(userId: number, assetName: string): Promise<any> {
    return new Promise((resolve, reject) => {
      connection.query(
        "SELECT `balance` FROM `wallets` WHERE `user_id` = ? AND `asset_name` = ? LIMIT 1",
        [userId, assetName],
        function (error, results, fields) {
          if (error) {
            reject(error);
          }
  
          resolve(results[0]);
        }
      );
    });
  }

  private async fetchLastUpdateTimeNotificationSent(): Promise<Date> {
    return new Promise((resolve, reject) => {
      connection.query(
        "SELECT `update_time_notification_sent` FROM `notification` LIMIT 1 ORDER BY `id` DESC",
        function (error, results, fields) {
          if (error) {
            reject(error);
          }
  
          if (results.length === 0) {
            resolve(new Date(Date.now() - 1000 * 10));
          }
  
          resolve(results[0].update_time_notification_sent);
        }
      );
    });
  }

  getOrders (limit: number, offset: number) {
    return new Promise((resolve, reject) => {
      connection.query(
        "SELECT * FROM `orders` LIMIT ? OFFSET ?",
        [limit, offset],
        function (error, results, fields) {
          if (error) {
            reject(error);
          }

          resolve(results);
        }
      );
    });
  }

  getOrder (id: number): Promise<any> {
    return new Promise((resolve, reject) => {
      connection.query(
        "SELECT * FROM `orders` WHERE `id` = ?",
        [id],
        function (error, results, fields) {
          if (error) {
            reject(error);
          }

          resolve(results[0]);
        }
      );
    });
  }

  async createOrder (data: {
    userId: number;
    pair: string;
    type: 'ASK' | 'BID';
    price: number;
    amount: number;
  }) {
    const [baseAsset, quoteAsset] = data.pair.split("/");
    const pair = await this.getPair(baseAsset, quoteAsset);
  
    if (!pair) {
      return Error("Pair not found");
    }

    // check if user has enough balance, use baseAsset for BID and quoteAsset for ASK
    const assetName = data.type === "BID" ? baseAsset : quoteAsset;
    const wallet = await this.getWallet(data.userId, assetName);

    if (!wallet || wallet.balance < data.amount) {
      return Error("Insufficient balance");
    }
  
    await producer.send({
      topic: "create-order",
      messages: [
        {
          value: JSON.stringify({
            user_id: data.userId,
            pair_id: pair.id,
            type: data.type,
            price: data.price,
            amount: data.amount,
          }),
        },
      ],
    });
  }

  async cancelOrder (id: number) {
    const order = await this.getOrder(id);
    if (order.status === "FILLED" || order.status === "CANCELLED") {
      return Error("Order cannot be cancelled");
    }
  
    await producer.send({
      topic: "cancel-order",
      messages: [
        {
          value: JSON.stringify({ id }),
        },
      ],
    });
  }
};
