import mongoose from "mongoose";

const connectDB = async (): Promise<void> => {
  const mongoUri = process.env.MONGODB_URI;

  if (!mongoUri) {
    if (process.env.NODE_ENV === "test") {
      return;
    }
    throw new Error("MONGODB_URI is not defined in environment variables");
  }

  await mongoose.connect(mongoUri);
  console.log("MongoDB connected");
};

export default connectDB;
