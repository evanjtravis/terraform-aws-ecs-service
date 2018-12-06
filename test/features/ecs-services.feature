Feature: We are able to instantiate all aws_ecs_service resources
    Background: Start with ecs-service module
        Given terraform module 'ecs-service'
            | varname | value                              |
            #---------|------------------------------------|
            | name    | "delete-me-behave-tf-$(RANDOM:10)" |
            | cluster | "example"                          |
        
        Given terraform file 'containers.json'
            """
            [{
              "name": "apache",
              "image": "httpd",
              "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                  "awslogs-stream-prefix": "prod",
                  "awslogs-group": "example",
                  "awslogs-region": "us-east-2"
                }
              },
              "portMappings": [
                {
                  "containerPort": 80
                }
              ]
            }]
            """
    
    
    Scenario: Instance of 'aws_ecs_service' 'awsvpc_all'
              Additionally:
                (A) create 'aws_alb_listener_rule' 'set_priority'
                (B) create 'aws_route53_record' 'default'
                (C) create 'aws_security_group_rule' 'service_in'
                (D) create 'aws_service_discovery_service' 'health_check_custom'
        # (B)
        #Create aws_rout53_record default
        Given terraform map 'alias'
            | varname | value                               |
            #---------|-------------------------------------|
            | domain  | "as-test.techservices.illinois.edu" |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "awsvpc"  |
            | container_name | "example" |
            | container_port | "80"      |
        
        Given terraform map 'load_balancer'
            | varname            | value                                               |
            #--------------------|-----------------------------------------------------|
            | name               | "public"                                            |
            | port               | "443"                                               |
            | container_name     | "apache"                                           |
            | container_port     | "80"                                                |
            | host_header        | "apache-example.as-test.techservices.illinois.edu" |
            # (A)                                                                      |
            #NOTE: Priority has a chance of clashing with existing rule priorities.    |
            # Create aws_alb_listener_rule set_priority                                |
            | priority           | "30000"                                             |
        
        Given terraform map 'network_configuration'
            | varname          | value                     |
            #------------------|---------------------------|
            | security_group   | "default"                 |
            | vpc              | "techservicesastest2-vpc" |
            | tier             | "public"                  |
            | assign_public_ip | "true"                    |
            # (C)                                          |
            # Create aws_security_group_rule service_in    |
            | ports            | "90"                      |
       
        Given terraform map 'service_discovery'
            | varname      | value                 |
            #--------------|-----------------------|
            | namespace_id | "ns-vf7wvzzwnp4d3rv2" |
        
        # (D)
        # Create aws_service_discovery_service health_check_custom
        Given terraform map 'service_discovery_health_check_custom_config'
            | varname           | value |
            #-------------------|-------|
            | failure_threshold | 1     |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                      | name                | count |
            #--------|-------------------------------|---------------------|-------|
            | create | aws_alb_listener_rule         | set_priority        |       |
            |        | aws_ecs_service               | awsvpc_all          |       |
            |        | aws_ecs_task_definition       | default             |       |
            |        | aws_lb_target_group           | default             |       |
            |        | aws_route53_record            | default             |       |
            |        | aws_security_group            | default             |       |
            |        | aws_security_group_rule       | lb_out              |       |
            |        | aws_security_group_rule       | service_icmp        |       |
            |        | aws_security_group_rule       | service_in_lb       |       |
            |        | aws_security_group_rule       | service_in          |       |
            |        | aws_security_group_rule       | service_out         |       |
            |        | aws_service_discovery_service | health_check_custom |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_ecs_service' 'all'
        Given terraform tfvars
            | varname     | value |
            #-------------|-------|
            | launch_type | "EC2" |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "bridge"  |
        
        Given terraform map 'load_balancer'
            | varname            | value                                               |
            #--------------------|-----------------------------------------------------|
            | name               | "private"                                           |
            | port               | "80"                                                |
            | container_name     | "apache"                                           |
            | container_port     | "80"                                                |
            | host_header        | "apache-example.as-test.techservices.illinois.edu" |
       
        Given terraform map 'service_discovery'
            | varname      | value                 |
            #--------------|-----------------------|
            | namespace_id | "ns-vf7wvzzwnp4d3rv2" |
            | type         | "SRV"                 |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                      | name          | count |
            #--------|-------------------------------|---------------|-------|
            | create | aws_alb_listener_rule         | default       |       |
            |        | aws_ecs_service               | all           |       |
            |        | aws_ecs_task_definition       | default       |       |
            |        | aws_lb_target_group           | default       |       |
            |        | aws_service_discovery_service | default       |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_ecs_service' 'awsvpc'
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "awsvpc"  |
            | container_name | "example" |
            | container_port | "80"      |
        
        Given terraform map 'network_configuration'
            | varname          | value                     |
            #------------------|---------------------------|
            | security_group   | "default"                 |
            | vpc              | "techservicesastest2-vpc" |
            | tier             | "public"                  |
            | assign_public_ip | "true"                    |
       
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                | name         | count |
            #--------|-------------------------|--------------|-------|
            | create | aws_ecs_service         | awsvpc       |       |
            |        | aws_ecs_task_definition | default      |       |
            |        | aws_security_group      | default      |       |
            |        | aws_security_group_rule | service_out  |       |
            |        | aws_security_group_rule | service_icmp |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_ecs_service' 'awsvpc_lb'
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "awsvpc"  |
            | container_name | "example" |
            | container_port | "80"      |
        
        Given terraform map 'load_balancer'
            | varname            | value                                               |
            #--------------------|-----------------------------------------------------|
            | name               | "public"                                            |
            | port               | "443"                                               |
            | container_name     | "apache"                                           |
            | container_port     | "80"                                                |
            | host_header        | "apache-example.as-test.techservices.illinois.edu" |
        
        Given terraform map 'network_configuration'
            | varname          | value                     |
            #------------------|---------------------------|
            | security_group   | "default"                 |
            | vpc              | "techservicesastest2-vpc" |
            | tier             | "public"                  |
            | assign_public_ip | "true"                    |
       
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                    | name          | count |
            #--------|-----------------------------|---------------|-------|
            | create | aws_alb_listener_rule       | default       |       |
            |        | aws_ecs_service             | awsvpc_lb     |       |
            |        | aws_ecs_task_definition     | default       |       |
            |        | aws_lb_target_group         | default       |       |
            |        | aws_security_group          | default       |       |
            |        | aws_security_group_rule     | lb_out        |       |
            |        | aws_security_group_rule     | service_icmp  |       |
            |        | aws_security_group_rule     | service_in_lb |       |
            |        | aws_security_group_rule     | service_out   |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_ecs_service' 'awsvpc_sd'
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "awsvpc"  |
            | container_name | "example" |
            | container_port | "80"      |
        
        Given terraform map 'network_configuration'
            | varname          | value                     |
            #------------------|---------------------------|
            | security_group   | "default"                 |
            | vpc              | "techservicesastest2-vpc" |
            | tier             | "public"                  |
            | assign_public_ip | "true"                    |
       
        Given terraform map 'service_discovery'
            | varname      | value                 |
            #--------------|-----------------------|
            | namespace_id | "ns-vf7wvzzwnp4d3rv2" |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                      | name         | count |
            #--------|-------------------------------|--------------|-------|
            | create | aws_ecs_service               | awsvpc_sd    |       |
            |        | aws_ecs_task_definition       | default      |       |
            |        | aws_security_group            | default      |       |
            |        | aws_security_group_rule       | service_icmp |       |
            |        | aws_security_group_rule       | service_out  |       |
            |        | aws_service_discovery_service | default      |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_ecs_service' 'default'
        Given terraform tfvars
            | varname     | value |
            #-------------|-------|
            | launch_type | "EC2" |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "bridge"  |
            | container_name | "apache" |
            | container_port | "80"      |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                | name    | count |
            #--------|-------------------------|---------|-------|
            | create | aws_ecs_service         | default |       |
            |        | aws_ecs_task_definition | default     |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_ecs_service' 'lb'
        Given terraform tfvars
            | varname     | value |
            #-------------|-------|
            | launch_type | "EC2" |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "bridge"  |
            | container_name | "apache" |
            | container_port | "80"      |
        
        Given terraform map 'load_balancer'
            | varname            | value                                               |
            #--------------------|-----------------------------------------------------|
            | name               | "public"                                            |
            | port               | "443"                                               |
            | container_name     | "apache"                                           |
            | container_port     | "80"                                                |
            | host_header        | "apache-example.as-test.techservices.illinois.edu" |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                    | name    | count |
            #--------|-----------------------------|---------|-------|
            | create | aws_alb_listener_rule       | default |       |
            |        | aws_ecs_service             | lb      |       |
            |        | aws_ecs_task_definition     | default     |       |
            #|        | aws_lb_listener_certificate | default |       |
            |        | aws_lb_target_group         | default |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_ecs_service' 'lb' PRIVATE
              - Proving that service discovery is causing the errors of other scenarios
                + 'aws_ecs_service' 'all'
                + etc.
        Given terraform tfvars
            | varname     | value |
            #-------------|-------|
            | launch_type | "EC2" |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "bridge"  |
            | container_name | "apache" |
            | container_port | "80"      |
        
        Given terraform map 'load_balancer'
            | varname            | value                                               |
            #--------------------|-----------------------------------------------------|
            | name               | "private"                                           |
            | port               | "80"                                                |
            | container_name     | "apache"                                           |
            | container_port     | "80"                                                |
            | host_header        | "apache-example.as-test.techservices.illinois.edu" |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                | name    | count |
            #--------|-------------------------|---------|-------|
            | create | aws_alb_listener_rule   | default |       |
            |        | aws_ecs_service         | lb      |       |
            |        | aws_ecs_task_definition | default     |       |
            |        | aws_lb_target_group     | default |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_ecs_service' 'sd'
        Given terraform tfvars
            | varname     | value |
            #-------------|-------|
            | launch_type | "EC2" |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "bridge"  |
        
        Given terraform map 'service_discovery'
            | varname        | value                 |
            #----------------|-----------------------|
            | namespace_id   | "ns-vf7wvzzwnp4d3rv2" |
            | type           | "SRV"                 |
            | container_name | "apache"             |
            | container_port | "80"                  |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                      | name    | count |
            #--------|-------------------------------|---------|-------|
            | create | aws_ecs_service               | sd      |       |
            |        | aws_ecs_task_definition       | default |       |
            |        | aws_service_discovery_service | default |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_service_discovery_service' 'health_check'
              Health check config can only be applied to a public namespace.
        Given terraform tfvars
            | varname     | value |
            #-------------|-------|
            | launch_type | "EC2" |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "bridge"  |
        
        Given terraform map 'load_balancer'
            | varname            | value                                               |
            #--------------------|-----------------------------------------------------|
            | name               | "public"                                            |
            | port               | "443"                                               |
            | container_name     | "apache"                                           |
            | container_port     | "80"                                                |
            | host_header        | "apache-example.as-test.techservices.illinois.edu" |
       
        Given terraform map 'service_discovery'
            | varname      | value                 |
            #--------------|-----------------------|
            | namespace_id | "ns-pomsm4cehdoviesw" |
            | type         | "SRV"                 |
        
        Given terraform map 'service_discovery_health_check_config'
            | varname           | value  |
            #-------------------|--------|
            | failure_threshold | 1      |
            | type              | "HTTP" |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                      | name         | count |
            #--------|-------------------------------|--------------|-------|
            | create | aws_alb_listener_rule         | default      |       |
            |        | aws_ecs_service               | all          |       |
            |        | aws_ecs_task_definition       | default      |       |
            |        | aws_lb_target_group           | default      |       |
            |        | aws_service_discovery_service | health_check |       |
        
        When we run terraform apply
    
    
    Scenario: Instance of 'aws_service_discovery_service' 'health_check_and_health_check_custom'
              - This configuration is not currently supported by AWS, cannot apply
              Health check config can only be applied to a public namespace.
        Given terraform tfvars
            | varname     | value |
            #-------------|-------|
            | launch_type | "EC2" |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "bridge"  |
            | container_name | "apache" |
            | container_port | "80"      |
        
        Given terraform map 'load_balancer'
            | varname            | value                                               |
            #--------------------|-----------------------------------------------------|
            | name               | "public"                                            |
            | port               | "443"                                               |
            | container_name     | "apache"                                           |
            | container_port     | "80"                                                |
            | host_header        | "apache-example.as-test.techservices.illinois.edu" |
       
        Given terraform map 'service_discovery'
            | varname      | value                 |
            #--------------|-----------------------|
            | namespace_id | "ns-pomsm4cehdoviesw" |
            | type         | "SRV"                 |
        
        Given terraform map 'service_discovery_health_check_config'
            | varname           | value |
            #-------------------|-------|
            | failure_threshold | 1     |
            | type              | "HTTP" |
        
        Given terraform map 'service_discovery_health_check_custom_config'
            | varname           | value  |
            #-------------------|--------|
            | failure_threshold | 1      |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                      | name                                 | count |
            #--------|-------------------------------|--------------------------------------|-------|
            | create | aws_alb_listener_rule         | default                              |       |
            |        | aws_ecs_service               | all                                  |       |
            |        | aws_ecs_task_definition       | default                              |       |
            #|        | aws_lb_listener_certificate   | default                              |       |
            |        | aws_lb_target_group           | default                              |       |
            |        | aws_service_discovery_service | health_check_and_health_check_custom |       |
        
        # Apply fails. Amazon conf issue.
        #When we run terraform apply
    
    
    