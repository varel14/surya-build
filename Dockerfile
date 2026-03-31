FROM ://amazonaws.com

WORKDIR /opt/ml/code

COPY . /opt/ml/code/

RUN apt-get update && apt-get install -y libgl1-mesa-glx libg>
RUN pip install --no-cache-dir surya-ocr sagemaker-inference

EXPOSE 8080
ENTRYPOINT ["python", "-m", "surya.serve"]
