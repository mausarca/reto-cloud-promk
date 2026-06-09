# Reto Ingeniero Cloud - Promarketing Chile - Candidato Mauricio Sarria

¡Te doy la bienvenida a mi solución para el **Reto Ingeniero Cloud** de Promarketing Chile! Este repositorio contiene el diseño arquitectónico, el aprovisionamiento como código (IaC) y la estimación de costos para una operación de **Casino Online** de alta disponibilidad desplegada en la región de Canadá (`ca-central-1`).

---

## 📂 Estructura del Repositorio

El proyecto está organizado de manera modular siguiendo las mejores prácticas de nomenclatura (`nombreRecurso-proyecto-operacion-num-region`), seguridad y segregación de funciones:

```text
├── terraform/
│   ├── main.tf          # Configuración de providers, versiones y locales de nomenclatura
│   ├── variables.tf     # Variables globales de entorno y región
│   ├── network.tf       # VPCs, Subredes (Públicas/Privadas), Gateways y VPC Peering
│   ├── instances.tf     # Grupos de seguridad, ALB, Instancias EC2, RDS y ElastiCache (Redis)
│   ├── s3.tf            # Almacenamiento privado de assets estáticos y políticas de cifrado
│   ├── cloudfront.tf    # Configuración de la CDN utilizando Origin Access Control (OAC)
│   ├── endpoints.tf     # VPC Endpoints (Gateway para S3 e Interface para Secrets Manager)
│   ├── monitoring.tf    # Grupo de logs en CloudWatch y configuración de buckets de auditoría
│   └── outputs.tf       # Valores de salida e información vital de la infraestructura
├── arquitectura/
│   ├── diagrama-arquitectura.png  # Exportación visual del diseño en Lucidchart
│   └── diagrama-arquitectura.lucid # Archivo fuente o enlace editable de Lucidchart
└── costos/
    └── calculadora-costos.md      # Desglose resumido del presupuesto mensual (AWS Calculator)

