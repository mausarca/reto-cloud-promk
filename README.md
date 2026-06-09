# Reto Ingeniero Cloud - Promarketing Chile - Candidato Mauricio Sarria

¡Te damos la bienvenida a mi solución para el **Reto Ingeniero Cloud** de Promarketing Chile! Este repositorio contiene el diseño arquitectónico, el aprovisionamiento como código (IaC) y la estimación de costos para una operación de **Casino Online** de alta disponibilidad desplegada en la región de Canadá (`ca-central-1`).

---

## 📂 Estructura del Repositorio

El proyecto se encuentra estructurado de forma modular y limpia, separando el código de infraestructura, los entregables financieros y el diseño visual en directorios independientes:

```text
├── arquitectura/
│   ├── Diagrama de Arquitectura.jpeg  # Exportación visual del diseño en Lucidchart
│   └── Diagrama de Arquitectura.pdf   # Versión del diagrama en alta resolución
├── costos/
│   ├── Calculadora de Costos Mensual.pdf   # Exportación ejecutable del presupuesto base de AWS
│   └── Calculadora de Costos Mensual.xlsx  # Hoja de cálculo complementaria con el desglose
├── terraform/
│   ├── cloudfront.tf    # Configuración de la CDN utilizando Origin Access Control (OAC)
│   ├── endpoints.tf     # VPC Endpoints (Gateway para S3 e Interface para Secrets Manager)
│   ├── instances.tf     # Grupos de seguridad, ALB, Instancias EC2, RDS y ElastiCache (Redis)
│   ├── main.tf          # Configuración de providers, versiones y locales de nomenclatura
│   ├── monitoring.tf    # Grupo de logs en CloudWatch y configuración de buckets de auditoría
│   ├── network.tf       # VPCs, Subredes (Públicas/Privadas), Gateways y VPC Peering
│   ├── outputs.tf       # Valores de salida e información vital de la infraestructura
│   ├── s3.tf            # Almacenamiento privado de assets estáticos y políticas de cifrado
│   └── variables.tf     # Variables globales de entorno y región
└── README.md            # Documentación principal del proyecto
