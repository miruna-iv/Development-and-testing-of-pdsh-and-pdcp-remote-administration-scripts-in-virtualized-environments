# pdsh & pdcp Remote Administration Utilities in Virtualized Environments

An automated distributed systems management toolset inspired by standard `pdsh` and `pdcp` utilities. Designed to execute parallel commands and distribute files across multiple remote Linux nodes efficiently and securely within a KVM-virtualized testbed.

---

## Key Features

- **Parallel Execution:** Uses background process spawning (`&`) and synchronization barriers (`wait`) to execute commands across cluster nodes concurrently rather than sequentially.
- **Robust Environment Checks (Sanity Checking):** Pre-execution validation verifies necessary dependencies (`ssh`, `scp` via `command -v`) and validates mandatory CLI arguments, preventing execution failures early.
- **Fail-Safe Security & Timeouts:** Integrated `-o ConnectTimeout=5` flags to prevent offline or unresponsive nodes from blocking the execution flow of the entire cluster.
- **Pre-computed Processing:** Local string substitution (`%h`, `%u`) is performed prior to process creation to optimize memory overhead and avoid redundant local operations inside child threads.
- **Automated Virtual Infrastructure Provisioning:** Includes `duplicateVM.sh`, an automated cluster expansion script utilizing `virt-customize` to inject unique hostnames directly into guest disk images before initial boot.

---

## Architecture & Infrastructure

### Virtualization Setup (KVM Hypervisor)
Instead of relying on basic container simulations, this project builds a robust, realistic data-center environment using **KVM (Kernel-based Virtual Machine)** on the host system:
1. **Master Node:** A manually configured Linux virtual machine serving as the base template.
2. **Automated Node Generation:** The `duplicateVM.sh` procedure automates guest disk cloning and configuration.
3. **Disk Image Customization:** Directly modifies virtual disk images using `virt-customize` to assign distinct `--hostname` identifiers prior to first launch.

```text
       +-------------------------------------------------+
       |                  Host System                    |
       |                (KVM Hypervisor)                 |
       +-----------------------+-------------------------+
                               |
            +------------------+------------------+
            |                                     |
    +-------v-------+                     +-------v-------+
    |  Node 1 (VM)  |  <--- SSH/SCP --->  |  Node 2 (VM)  |
    +---------------+   (Parallel Exec)   +---------------+
