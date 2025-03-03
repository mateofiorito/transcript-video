# Use an official Node.js image based on Debian (buster)
FROM node:16-buster

# Update apt-get and install FFmpeg, Python3 and pip
RUN apt-get update && apt-get install -y ffmpeg python3 python3-pip

# Install Python dependencies: OpenAI Whisper and yt-dlp
# Whisper will handle transcription and yt-dlp is used to download YouTube videos.
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
