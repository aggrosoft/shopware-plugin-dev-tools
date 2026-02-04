### 🛑 CRITICAL EXECUTION RULES
**You are working in a local environment, but code execution happens inside a Docker container.**

1.  **NO Host Commands:** NEVER execute `php`, `composer`, `node`, or `npm` commands directly. The host environment does not match the runtime environment.
2.  **USE THE DOCKER COMMANDS:** You MUST use the specific commands provided below to bridge your actions into the container.

### ✅ Command Reference (Copy & Paste these)

Use these EXACT commands. They automatically determine the correct plugin directory inside the container.

| Intent | Command to Execute |
| :--- | :--- |
| **Run All Tests** | `docker exec -t {{CONTAINER_ID}} bash -c "cd custom/plugins/$(basename $(pwd)) && ../../../vendor/bin/phpunit"` |
| **Run Specific Test** | `docker exec -t {{CONTAINER_ID}} bash -c "cd custom/plugins/$(basename $(pwd)) && ../../../vendor/bin/phpunit --filter NameOfTest"` |
| **Fix Code Style (ECS)** | `docker exec -t {{CONTAINER_ID}} bash -c "cd custom/plugins/$(basename $(pwd)) && ../../../vendor/bin/ecs check --fix"` |
| **Static Analysis (PHPStan)** | `docker exec -t {{CONTAINER_ID}} bash -c "cd custom/plugins/$(basename $(pwd)) && ../../../vendor/bin/phpstan analyse"` |
| **Build Storefront (JS/SCSS)** | `docker exec -t {{CONTAINER_ID}} bash -c "./bin/build-storefront.sh"` |
| **Watch Storefront** | `docker exec -t {{CONTAINER_ID}} bash -c "./bin/build-storefront.sh -w"` |
| **Refresh Plugin** | `docker exec -t {{CONTAINER_ID}} bash -c "bin/console plugin:refresh && bin/console cache:clear"` |
| **Create Migration** | `docker exec -t {{CONTAINER_ID}} bash -c "bin/console database:create-migration -p $(basename $(pwd))"` |

**Note:** If a command fails because "file not found", ensure you are in the root directory of the plugin locally.
