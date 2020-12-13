from diagrams import Diagram, Cluster
from diagrams.onprem.compute import Server
from diagrams.onprem.network import Internet
from diagrams.oci.network import LoadBalancer
from diagrams.onprem.iac import Terraform
from diagrams.onprem.client import User


with Diagram("Load balanced application on droplets", show=False, direction="LR"):

    internet = Internet("Internet")
    internet

    with Cluster("home"):
        user = User("you")
        terraform = Terraform("terraform apply")
        user >> terraform >> internet

    with Cluster("DigitalOcean"):
        pub_lb = LoadBalancer("pub-lb-burrito-prod")
        web0 = Server("web0-burrito-prod")
        web1 = Server("web1-burrito-prod")
        
        internet >> pub_lb
        pub_lb >> web0
        pub_lb >> web1
    