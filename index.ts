import express from 'express';
import jwt from 'jsonwebtoken';
import OrderService from './orders/service';

interface CustomRequest extends express.Request {
  userId?: string;
}

const orderService = new OrderService();
const app = express();

app.use(express.json());
app.use((req: CustomRequest, res, next) => {
  const token = req.cookies.token;

  if (!token) {
    return res.status(403).send({ auth: false, message: 'No token provided.' });
  }

  jwt.verify(token, process.env.SECRET_KEY as string, (err, decoded) => {
    if (err) {
      return res.status(401).send({ auth: false, message: 'Failed to authenticate token.' });
    }

    req.userId = decoded.id;
    next();
  });
});

app.get('/orders', async (req, res) => {
  const page = parseInt(req.query.page as string);
  const limit = parseInt(req.query.limit as string);
  const offset = (page - 1) * limit;

  const orders = await orderService.getOrders(limit, offset);
  res.json(orders);
});

app.get('/orders/:id', async (req, res) => {
  const id = parseInt(req.params.id);
  const order = await orderService.getOrder(id);
  res.json(order);
});

app.post('/orders', async (req, res) => {
  const order = await orderService.createOrder(req.body);
  if (order instanceof Error) {
    res.status(400);
    res.json({ error: order.message });
    return;
  }

  res.json({ message: 'Order Queued for creation' });
});

app.post('/orders/:id/cancel', async (req, res) => {
  const id = parseInt(req.params.id);
  const order = await orderService.cancelOrder(id);
  if (order instanceof Error) {
    res.status(400);
    res.json({ error: order.message });
    return;
  }

  res.json({ message: 'Order Queued for cancellation' });
});
