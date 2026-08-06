# Narratives, AI and Automation — Replication Code

This repository contains the replication code for the paper
**"Why Artificial Intelligence is not a Salient Issue: Politicizing AI Reduces
Mobilization Potential"**.

## The paper in brief

The project studies what citizens think about artificial intelligence and
automation, and how political narratives shape (or fail to shape) those
opinions. It builds on a large, pre-registered survey of adult citizens in
Italy, Germany and the United States, measuring knowledge about AI, beliefs
about its impact on jobs, demand for policy intervention, and willingness to
sign a real online petition. A randomized experiment exposes respondents to
alternative political framings (optimistic, balanced, pessimistic) to estimate
how much narratives move attitudes and policy preferences.

## Repository structure

The code is organized into two folders, each containing the Stata `.do` files
that reproduce the analysis for one part of the project:

- **`main_study/`** — the main analysis: dataset preparation, descriptive
  statistics, policy and petition (signature) outcomes, heterogeneity and
  robustness checks, and the figures (including the regional maps of Italy).

- **`follow_up/`** — the follow-up study: dataset preparation and descriptive
  statistics for the additional data collection.

Run the numbered scripts in order within each folder, starting with the
dataset-preparation file.
