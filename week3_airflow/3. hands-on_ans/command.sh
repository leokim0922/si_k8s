0. 
 - create a cluster
 - create a registry
 - connect to the cluster
# https://www.bluematador.com/learn/kubectl-cheatsheet
- go to 2. hands-on

1. create a cluster
# doctl auth init --context k8s-si
# doctl auth switch --context k8s-si
doctl kubernetes options sizes
doctl kubernetes cluster create si-airflow --tag si-airflow --auto-upgrade=true --node-pool "name=mypool;count=2;auto-scale=true;min-nodes=1;max-nodes=3;size=s-4vcpu-8gb;tag=si-airflow"

2. connect to the cluster
kubectl config get-contexts
kubectl config current-context
kubectl config use-context <context_name>

3. install airflow on kubernetes
kubectl create namespace airflow
kubectl config set-context --current --namespace=airflow
kubectl config get-contexts

helm repo add apache-airflow https://airflow.apache.org
helm repo update
helm search repo airflow
helm install airflow apache-airflow/airflow --namespace airflow --debug
# if fails: helm upgrade -i airflow apache-airflow/airflow --namespace airflow --debug
# Roll back: helm rollback
# Remove: helm uninstall airflow -n airflow
kubectl get pods -n airflow
# Default is CeleryExecutor
# Workers are running
helm ls -n airflow

######################################################################
NOTES:
Thank you for installing Apache Airflow 2.7.1!

Your release is named airflow.
You can now access your dashboard(s) by executing the following command(s) and visiting the corresponding port at localhost in your browser:

Airflow Webserver:     kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow
Default Webserver (Airflow UI) Login credentials:
    username: admin
    password: admin
Default Postgres connection credentials:
    username: postgres
    password: postgres
    port: 5432

You can get Fernet Key value by running the following:
echo Fernet Key: $(kubectl get secret --namespace airflow airflow-fernet-key -o jsonpath="{.data.fernet-key}" | base64 --decode)
######################################################################

4. Custom Airflow
# Create a registry on UI
# Intergate with k8s
# Show Dag and explain why we need custom image

doctl registry login
docker build -t airflow-custom .
docker buildx build --platform=linux/amd64 -t airflow-custom .
docker tag airflow-custom registry.digitalocean.com/<your-registry-name>/airflow-custom
docker tag airflow-custom registry.digitalocean.com/si-k8s-session/airflow-custom
docker push registry.digitalocean.com/si-k8s-session/airflow-custom

helm show values apache-airflow/airflow > values.yaml
# modify defaultAirflowRepository to your registry (registry.digitalocean.com/si-k8s-session/airflow-custom)
# modify tag to latest
# modify executor to KubernetesExecutor

kubectl get secrets -n airflow
# if kubernetes.io/dockerconfigjson not found, create a secret
# UI regsitry file download
# kubectl create secret generic regcred --from-file=.dockerconfigjson=<path/to/.docker/config.json> --type=kubernetes.io/dockerconfigjson -n airflow
# registry:
#   secretName: generic
helm upgrade --install airflow apache-airflow/airflow -n airflow -f values.yaml --debug

4. DB setting
create a postgres
kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow
docker pull dpage/pgadmin4
docker run --name my-pgadmin -p 82:80 -e 'PGADMIN_DEFAULT_EMAIL=jk23oct@gmail.com' -e 'PGADMIN_DEFAULT_PASSWORD=password123' dpage/pgadmin4
add postgres connection in UI

5. DAG with GitSync
Create a private key with ssh-keygen if not exists
kubectl create secret generic airflow-ssh-git-secret --from-file=gitSshKey=/Users/jonghyeokkim/.ssh/id_rsa -n airflow
kubectl get secrets -n airflow
*update gitSync: values.yaml

# Modify values.yaml
#   gitSync:
#     enabled: true

#     # git repo clone url
#     # ssh example: git@github.com:apache/airflow.git
#     # https example: https://github.com/apache/airflow.git
#     repo: git@github.com:jka236/sidag.git
#     branch: main
#     rev: HEAD
#     depth: 1
#     # the number of consecutive failures allowed before aborting
#     maxFailures: 0
#     # subpath within the repo where dags are located
#     # should be "" if dags are at repo root
#     subPath: ""
#     sshKeySecret: airflow-ssh-git-secret

helm upgrade --install airflow apache-airflow/airflow -n airflow -f values.yaml --debug
kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow

6. run a dag
7. check pgadmin
