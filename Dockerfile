# Use an official Node.js image based on Debian Bullseye (has newer Python)
FROM node:18-bullseye

# Update apt-get and install FFmpeg, Python3 and pip
RUN apt-get update && apt-get install -y ffmpeg python3 python3-pip

# Upgrade pip to ensure we get the latest wheels
RUN pip3 install --upgrade pip

# Install Python dependencies: OpenAI Whisper and yt-dlp
# (With a newer Python version, Triton should install correctly.)
RUN pip3 install --no-cache-dir openai-whisper yt-dlp

# Set the working directory in the container
WORKDIR /app

# Copy package files and install Node.js dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the application code to the container
COPY . .

# Expose the port that your app listens on
EXPOSE 8080

# Start the Node.js application
CMD ["node", "server-segment-two.js"]
