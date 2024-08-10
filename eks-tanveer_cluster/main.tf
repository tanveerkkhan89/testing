name: CI/CD Pipeline

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Check out repository
        uses: actions/checkout@v3

      - name: Set up Java JDK
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'adopt'

      - name: Build with Maven
        run: mvn clean package

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Build Docker image
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/my-image:${{ github.sha }} .

      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Push Docker image
        run: |
          docker push ${{ secrets.DOCKER_USERNAME }}/my-image:${{ github.sha }}

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Check out repository
        uses: actions/checkout@v3

      - name: Install AWS CLI v2
        run: |
          curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
          unzip awscliv2.zip
          sudo ./aws/install
          aws --version

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Set up kubectl
        uses: kubernetes-sigs/setup-kubectl@v2
        with:
          version: '1.23.0'

      - name: Set up EKS Cluster
        run: |
          aws eks update-kubeconfig --name example-eks-cluster
          kubectl config use-context arn:aws:eks:us-east-1:123456789012:cluster/example-eks-cluster

      - name: Deploy with Helm
        run: |
          helm upgrade --install my-release ./my-spring-app --set image.tag=${{ github.sha }}
