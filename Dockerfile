e official Node.js LTS image
FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy app source
COPY . .

# Expose app port
EXPOSE 8080

# Start app
CMD ["node", "index.js"]

