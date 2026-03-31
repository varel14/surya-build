#!/bin/bash

# Configuration
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_NAME="surya-ocr-sagemaker"
IMAGE_TAG="latest"
FULL_IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}/${REPO_NAME}:${IMAGE_TAG}"

# 1. Connexion à ECR (Image de base AWS)
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin 763104351884.dkr.ecr.${REGION}.amazonaws.com

# 2. Création du dépôt ECR s'il n'existe pas
aws ecr describe-repositories --repository-names ${REPO_NAME} || \
aws ecr create-repository --repository-name ${REPO_NAME}

# 3. Build de l'image
docker build -t ${REPO_NAME} .

# 4. Tag et Push
docker tag ${REPO_NAME}:${IMAGE_TAG} ${FULL_IMAGE_URI}
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
docker push ${FULL_IMAGE_URI}

echo "Image poussée avec succès : ${FULL_IMAGE_URI}"
