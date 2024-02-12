import { Consumer, Producer } from "kafkajs";

export class OrderConsumer {
  private readonly producer: Producer;
  private readonly consumer: Consumer;

  constructor(producer: Producer, consumer: Consumer) {
    this.producer = producer;
    this.consumer = consumer;
  }

  public async consume() {
    await this.consumer.connect();
    await this.consumer.subscribe({ topic: "create-order" });

    await this.consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        if (message && message.value) {
          if (topic == 'create-order') {
            // call stored procedure to create order
            
          }
  
          console.log("Received message", {
            value: message.value.toString(),
          });

          // const order = JSON.parse(message.value.toString());
          // await this.producer.send({
          //   topic: "order",
          //   messages: [{ value: JSON.stringify(order) }],
          // });
        }
      },
    });
  }
}