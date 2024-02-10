import { Kafka } from "kafkajs";

const kafka = new Kafka({
  clientId: "blockxchange",
  brokers: ["kafka1:9092", "kafka2:9092"],
});

export const producer = kafka.producer();
