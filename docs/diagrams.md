# Architecture diagrams — how to make good ones

Every project needs one. A good diagram is what makes a recruiter stop scrolling.

## Tools (pick one)

| Tool | Best for | Notes |
|---|---|---|
| **draw.io / diagrams.net** | Polished, hand-placed diagrams | Free. Enable the *Azure* shape library. Save the `.drawio` file **and** export PNG/SVG. VS Code has a Draw.io extension so the source lives in the repo. |
| **Mermaid** | Quick diagrams that render directly on GitHub | Already used in each project README as a starting sketch. No official Azure icons. |
| **Python `diagrams` library** | Diagrams as code, with real Azure icons | `pip install diagrams` (needs Graphviz). Commit the `.py` file, generate the PNG. Nice interview talking point: "my diagrams are code too". |
| **Excalidraw** | Whiteboard-style sketches | Good for early design / blog posts |

Example with `diagrams`:
```python
from diagrams import Diagram, Cluster
from diagrams.azure.network import FrontDoors
from diagrams.azure.compute import AppServices
from diagrams.azure.database import SQLDatabases

with Diagram("Self-Healing Web App", filename="docs/architecture", show=False):
    fd = FrontDoors("Front Door")
    with Cluster("Region: Central India"):
        app = AppServices("App Service")
        db = SQLDatabases("Azure SQL")
    fd >> app >> db
```

## Rules for a clear diagram

1. **Flow left → right** (or top → bottom). Users / sources on the left, data stores on the right.
2. **Group with boxes**: subscription → region → VNet → subnet. Boundaries show you understand networking.
3. **Use official Azure icons** and label each with the *service name* and its *role* ("Service Bus — orders queue").
4. **Number the arrows** (1, 2, 3…) and explain the steps in the README underneath.
5. Show **identity** (managed identity / OIDC) and **monitoring** (Log Analytics) — most people forget these, so including them makes you stand out.
6. Use colour sparingly: e.g. red dashed arrows for the failure / failover path.
7. One diagram for the big picture; optionally a second for a detail (network, CI/CD, failover sequence).
