from diagrams import Diagram, Cluster
from diagrams.onprem.compute import Server
from diagrams.onprem.network import Internet
from diagrams.onprem.iac import Terraform
from diagrams.onprem.client import User


with Diagram("creating multiple droplets with terraform", show=False, direction="LR"):

    internet = Internet("Internet")
    internet

    with Cluster("home"):
        user = User("you")
        terraform = Terraform("terraform apply")
        user >> terraform >> internet

    with Cluster("DigitalOcean"):
        web0 = Server("web0-burrito-prod")
        web1 = Server("web1-burrito-prod")
        internet >> web0
        internet >> web1
    