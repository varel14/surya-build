# Utilisation de l'image de base PyTorch AWS (optimisée GPU)
FROM 763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-inference:2.0-gpu-py310
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
ENV SAGEMAKER_PROGRAM=inference.py
ENV SAGEMAKER_SUBMIT_DIRECTORY=/opt/ml/model/code
ENV PYTHONUNBUFFERED=1

EXPOSE 8080

# ENTRYPOINT ["python", "-m", "surya.serve"]
