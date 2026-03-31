# Utilisation de l'image de base PyTorch AWS (optimisée GPU)
FROM 763104351884.dkr.ecr.eu-north-1.amazonaws.com/pytorch-inference:2.5.1-gpu-py311-cu121-ubuntu22.04-sagemaker

# Dossier de travail standard SageMaker
WORKDIR /opt/ml/code

# Installation des dépendances système pour OpenCV
RUN apt-get update && apt-get install -y libgl1-mesa-glx libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# Copie et installation des dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie de votre code source
COPY . /opt/ml/code/

# Configuration pour le serveur d'inférence SageMaker
ENV SAGEMAKER_PROGRAM inference.py
EXPOSE 8080

ENTRYPOINT ["python", "-m", "surya.serve"]
