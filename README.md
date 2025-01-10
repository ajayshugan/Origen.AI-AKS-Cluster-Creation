# Origen.AI-AKS-Cluster-Creation

Overview:

This project involves setting up a web application with a frontend, backend, and database, all hosted on an Azure Kubernetes Service (AKS) cluster. We use Terraform to define the infrastructure and Helm charts to deploy the application. Throughout the project, we focus on security, scalability, and performance best practices.

Prerequisites:
    Before getting started, make sure you have the following:

    •	Terraform: Install and configure Terraform on your machine. You can follow this installation guide.
    •	Helm: Install Helm, which is used for managing Kubernetes applications. See the Helm installation guide.
    •	Azure CLI: Install Azure CLI for managing your Azure resources. The installation guide is available here.
    •	Kubernetes CLI (kubectl): You’ll need kubectl to manage and monitor Kubernetes clusters. Follow the installation guide.

Solution Components:
    •	AKS Cluster Creation: Terraform defines the infrastructure and provisions an AKS cluster, where the web application components will be hosted.
    •	Application Deployment: The application (frontend, backend, and MongoDB database) is deployed using Helm charts and Kubernetes manifests.

Key Optimizations and Features:
    •	Cluster Autoscaling: The AKS cluster is set to automatically adjust the number of nodes based on resource demand.
    •	Horizontal Pod Autoscaler (HPA): Configured to scale the frontend and backend pods based on their CPU utilization.
    •	Replica Management: To ensure high availability, we set the number of replicas for both frontend and backend to 3.
    •	Network Policies: These are implemented to control traffic between pods, enhancing security.
    •	Persistent Storage: The MongoDB database uses 10Gi of persistent storage to improve data management.
    •	Monitoring: Azure Monitor is enabled to track the AKS cluster’s performance, collecting metrics and logs.
    •	Load Balancer: A LoadBalancer-type service is configured for the frontend to allow external traffic.
    •	Terraform State Management: The Terraform state file is securely stored in Azure Blob Storage to maintain infrastructure consistency across 
       deployments and enable collaboration.

Project Setup
1. Clone the repository
		git clone https://github.com/ajayshugan/Origen.AI-AKS-Cluster-Creation.git
		cd <repository-directory>

2. Configure Azure Authentication
    Log in to your Azure account using the Azure CLI:
		az login

3. Terraform Configuration
  •	Update the main.tf file with your Azure subscription details and other parameters (e.g., resource group name, AKS cluster name, etc.).
  •	Initialize Terraform:
        terraform init
  •	Create an execution plan:
         terraform plan
  •	Apply the plan to create the AKS cluster:
       	terraform apply

4. Deploy the Application with Helm

     Ensure kubectl is connected to your newly created AKS cluster:
     az aks get-credentials --resource-group <your-resource-group> --name <your-cluster-name>

    Install the Helm chart for your web application:
	  helm install <release-name> ./helm-chart-directory


Monitoring and Scaling
      •	Use Azure Monitor to track the performance and health of your AKS cluster.
      •	The Horizontal Pod Autoscaler ensures that pods scale automatically based on resource demand.
      •	Network policies provide additional security by controlling traffic between pods.

Security Best Practices
      •	Network policies restrict unnecessary traffic between pods, enhancing security.
      •	Terraform state is securely managed in Azure Blob Storage.
      •	Role-based access control (RBAC) ensures proper authorization and access management.

Additional Improvements
      •	Azure Key Vault is leveraged for securely managing sensitive information like database credentials and API keys.

