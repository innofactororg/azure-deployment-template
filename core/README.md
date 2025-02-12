**Infrastructure Bicep (Governed by AWF)**

For the Infrastructure Bicep, the focus is on shared infrastructure that is governed by AWF. This could include shared networks, storage accounts, or policy enforcement. The infra is responsible for deploying resources like virtual networks (VNets), network security groups (NSGs), route tables, and governance policies (e.g., diagnostics and security settings). These shared resources are centrally managed by AWF, ensuring compliance, security, and consistency across all solutions.

**Solution Bicep (Managed Autonomously by Teams)**

For the Solution Bicep, teams have the freedom to deploy and manage their applications, but they can rely on the infrastructure defined by AWF. This allows solution teams to deploy resources specific to their application. While the solution teams have autonomy over these resources, they are integrated with shared infrastructure like VNets and monitoring systems, ensuring security and governance.

**Key Points:**

- Infrastructure Governance: All shared infrastructure (e.g., VNets, governance policies) is defined in the infra_spoke_template folder and controlled by AWF. The infra Bicep defines the foundational components that all solutions rely on.
- Solution Autonomy: Teams can manage their application-specific resources independently in the solution_spoke_template folder. However, they rely on outputs from the shared infrastructure, like virtual networks, to ensure their resources are securely integrated with the rest of the environment.
- Pipelines: The infrastructure pipeline runs first, deploying the shared resources (e.g., networks, policies). The solution pipelines depend on the outputs from this infrastructure, ensuring that the solutions are deployed securely and in compliance with organizational governance.

This setup maintains governance for shared infrastructure while providing autonomy to the solution teams for managing their applications, ensuring both compliance and flexibility.