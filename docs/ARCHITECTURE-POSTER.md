# Architecture Poster

```mermaid
flowchart LR
    subgraph source [Source Data]
        artist[ARTIST]
        album[ALBUM]
        track[TRACK]
        customer[CUSTOMER]
        employee[EMPLOYEE]
        invoice[INVOICE]
        line[INVOICE_LINE]
        playlist[PLAYLIST]
        pt[PLAYLIST_TRACK]
    end

    subgraph ontology [Ontology Layer]
        ontTables[ONT_* Metadata Tables]
        concrete[V_* Concrete Views]
        abstract[VW_ONT_* Abstract Views]
    end

    subgraph semantic [Semantic Models]
        base[SV_SAM_DRIFT_BASE]
        ont[SV_SAM_DRIFT_ONTOLOGY]
    end

    subgraph agent [Agent Layer]
        sam[Sam-the-Snowman]
        evals[SAM_EVALUATION_DATA]
    end

    source --> ontTables
    source --> concrete
    concrete --> abstract
    source --> base
    abstract --> ont
    base --> sam
    ont --> sam
    evals --> sam
```

## Flow Summary

1. Deterministic Drift data is loaded from repository-hosted Parquet files.
2. Ontology metadata and typed/abstract views model business concepts over source tables.
3. Two semantic views expose source-level and abstraction-level analytics paths.
4. Sam routes user questions across these tools and is evaluated on the same hard question set each run.
