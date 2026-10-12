# Designing Data-Intensive Applications — Martin Kleppmann, 2017

## Contents

- [Why this book is in the loop](#why-this-book-is-in-the-loop)
- [The argument](#the-argument)
- [Enforceable rules](#enforceable-rules)
- [Latency and scale budgets](#latency-and-scale-budgets)
- [Applied to Postgres + Redis + BullMQ + vector search](#applied-to-postgres--redis--bullmq--vector-search)
- [Review prompts](#review-prompts)
- [Sources](#sources)

## Why this book is in the loop

Almost every defect that survives review in this monorepo is a _data_ defect, not a
logic defect. The function is correct; what is wrong is what happens when it runs
twice, runs concurrently with another copy of itself, runs against a replica that is
three seconds stale, runs after a schema change that a still-deployed worker has not
seen, or runs over a table that has grown from 400 rows to 4 million. Those are the
exact failure classes DDIA enumerates. The book is the closest thing our industry has
to a shared vocabulary for them — "read-committed does not prevent lost updates",
"at-least-once means idempotent or wrong", "backward compatible means new code reads
old data" — and a shared vocabulary is what a factory of agents needs most, because
agents are excellent at producing locally correct code and terrible at noticing that
the correctness is local.

We keep it in the loop for three concrete jobs. First, as a **checklist generator**:
the "Enforceable rules" table below is derived from it and is meant to be run against
every diff that touches a repository, a migration, a queue handler, or a cache. Second,
as a **naming discipline**: when a reviewer says "this is a lost update" or "this needs
an outbox", that phrase names a known failure with a known remedy, and the conversation
ends in one exchange instead of five. Third, as a **budget forcing function**: DDIA's
opening chapter insists that "scalability" is meaningless without a stated load
parameter and a stated percentile, which is why every endpoint we ship is expected to
carry a latency budget rather than a vibe.

## The argument

Kleppmann opens by refusing the word "performance" and replacing it with three
non-negotiable properties: **reliability**, **scalability**, **maintainability**.
Reliability is defined operationally — the system continues to work correctly _in the
presence of faults_ — and the key move is the distinction between a fault (one
component deviating from spec) and a failure (the system as a whole stopping service).
The engineering job is not to eliminate faults, which is impossible, but to prevent
faults from cascading into failures. This reframing is why fault injection is a design
activity and not a QA afterthought: if you never exercise the fault path, you have not
built a tolerance, you have built a hope. Scalability is likewise reframed as a
question you cannot ask abstractly. You must name the _load parameter_ (requests per
second, ratio of reads to writes, fan-out per event, concurrent connections) and you
must describe response time as a **distribution**, specifically high percentiles, not
a mean — because means are dominated by the cheap requests and the p99 is where your
most valuable users live. Head-of-line blocking and tail-latency amplification follow:
a request that fans out to ten backends waits on the slowest of ten, so a 1-in-100 slow
backend becomes a 1-in-10 slow request. Maintainability is broken into operability,
simplicity (specifically the removal of _accidental_ complexity via good abstraction),
and evolvability — the ability to change the system as requirements change, which the
rest of the book keeps returning to under the name "schema evolution".

The **data models** chapter argues that the relational/document/graph debate is really
a debate about where the joins live. Document models win when the access pattern is a
tree loaded whole and the relationships are one-to-many with locality; they lose the
moment you need many-to-many, because you end up doing joins in application code, badly
and without transactions. Relational models win at many-to-many and at supporting query
patterns you did not anticipate — which is most query patterns, because the ones you
anticipated are the ones you would have optimized anyway. Graph models win when the
connections themselves are the data and traversal depth is unbounded. The durable
insight is that **schema-on-read is not "no schema", it is an implicit schema enforced
by every reader**, which is strictly worse than an explicit one unless the data is
genuinely heterogeneous. This is the argument that should be quoted every time someone
proposes a `jsonb` column to avoid writing a migration.

**Storage engines** contrasts B-trees with log-structured merge trees. B-trees mutate
pages in place, giving predictable read performance, straightforward range scans, and
strong support for the transactional machinery already built around them; their costs
are write amplification from page splits and the write-ahead log, and fragmentation.
LSM trees buffer writes in memory, flush sorted runs to disk, and compact in the
background; they win on write throughput and compression, and lose on read latency
variance (a read may touch many levels) and on compaction competing with foreground
traffic. The transferable lesson is not "pick one" — it is that **every index is a
write-side tax paid for a read-side benefit**, and a team that adds indexes without
naming the query they serve is levying the tax without buying anything. This is also
where secondary indexes, clustered indexes, and the covering-index idea come from,
which map directly onto our Postgres work.

**Encoding and evolution** is the chapter most under-read and most relevant to a
service running rolling deploys. During any deploy there are two versions of the code
running simultaneously, so data written by the new code must be readable by the old
(**forward compatibility**) and data written by the old must be readable by the new
(**backward compatibility**). Kleppmann shows how Protobuf/Thrift/Avro achieve this
with field tags and reader/writer schema resolution, and the same discipline applies
verbatim to a Postgres migration: adding a nullable column is safe, adding a NOT NULL
column without a default is not, renaming a column is a two-deploy expand/contract
operation, and dropping a column must wait until no deployed code reads it. Every
"the deploy broke prod for ninety seconds" incident is a compatibility violation.

**Replication** covers single-leader, multi-leader, and leaderless, and spends most of
its energy on the consequences of asynchronous replication: read-after-write anomalies
(you don't see your own comment), monotonic read violations (you see a comment, refresh,
and it's gone), and consistent-prefix violations (you see the answer before the
question). The remedies — read your own writes from the leader, sticky routing, version
tokens — are the ones you reach for the day you add a read replica. Multi-leader and
leaderless setups force the conflict-resolution question, where last-write-wins is
exposed as a lossy choice rather than a neutral default.

**Partitioning** is about spreading load without creating hot spots. Key-range
partitioning gives efficient range scans and terrible skew for sequential keys
(timestamps, monotonic ids); hash partitioning gives even distribution and destroys
range scans. Secondary indexes must be either local (query all partitions, scatter-
gather) or global (write to a different partition than the primary, which makes writes
cross-partition). Rebalancing must never be "hash mod N".

**Transactions** is the chapter with the highest defect-prevention-per-page ratio. ACID
is exposed as a marketing term whose only sharply defined member is durability;
"isolation" in particular is a spectrum with named anomalies. Read committed prevents
dirty reads and dirty writes but permits read skew and lost updates. Snapshot isolation
(Postgres `REPEATABLE READ`) prevents read skew via MVCC but still permits write skew
and phantoms — the classic on-call doctors example, where two concurrent transactions
each check "at least one other doctor is on call", each sees a stale snapshot, and both
succeed, leaving zero. Serializable is the only level that makes concurrent execution
equivalent to some serial order, achievable via actual serial execution, two-phase
locking, or serializable snapshot isolation (SSI, Postgres `SERIALIZABLE`), which is
optimistic and therefore aborts under contention — meaning **choosing serializable
obliges you to write a retry loop**. The operational rule that falls out: any invariant
spanning more than one row must have its isolation level chosen deliberately and
written down, because the default is read committed and read committed will not hold it.

**The trouble with distributed systems** is the honesty chapter: unreliable networks
(a lost message is indistinguishable from a slow one), unreliable clocks (wall clocks
jump, monotonic clocks don't compare across machines, so timestamp ordering across
nodes is a fiction), and process pauses (GC, VM migration, page faults) that make a
node believe it still holds a lease it lost. Hence fencing tokens, hence the
insistence that a distributed lock without a fencing token is not a lock. **Consistency
and consensus** then builds up linearizability (a recency guarantee, expensive, and
what people actually mean when they say "consistent"), causality and total order
broadcast, and consensus algorithms, closing with the observation that most systems
should buy consensus from a coordination service rather than implementing it.

**Derived data** splits the world into systems of record and derived systems (caches,
indexes, materialized views, search indexes) and argues that derived data is always
recomputable from the source — which makes it forgiving of bugs, since you can rebuild
it. Batch processing (MapReduce and successors) is presented as the deterministic,
retryable ideal; stream processing generalizes it to unbounded input, introducing event
time versus processing time, windowing, and the change-data-capture pattern, where the
database replication log becomes the event stream that keeps derived systems in sync.
The final chapter's argument — **unbundling the database**, treating the log as the
integration point, and preferring dataflow over synchronous cross-system writes — is
the intellectual origin of the transactional outbox.

**What is dated in 2026.** The technology survey is a period piece: the specific
comparisons of Riak/Voldemort/CouchDB, the framing of MapReduce as a live contender,
the assumption that "NewSQL" is a fringe bet, and the near-absence of cloud-native
managed services, serverless data stores, and separated storage/compute architectures.
Postgres itself has moved substantially (logical replication, better partitioning,
`MERGE`, extensions like pgvector that the book could not have anticipated). Nothing in
the book addresses vector search, embedding drift, or LLM-era workloads where a "query"
costs a dollar and two seconds. Consensus is now a commodity you rent. Treat every
named product in the book as an example, never as a recommendation.

**What is eternal.** The failure taxonomy and the vocabulary. Percentiles over means.
The fault/failure distinction. Backward and forward compatibility as a deploy-time
constraint. The isolation-anomaly catalogue and the fact that defaults do not hold
multi-row invariants. At-least-once delivery implying idempotence. Clocks not being
ordering. Derived data being rebuildable, and that being a feature. Indexes as a
write-side tax. These are properties of the problem, not of 2017's tooling, and they
will outlive every database in the book.

## Enforceable rules

| #   | Rule                                                                                                                                                                      | How to check                                                                                                                                                                                                                                                                             | Severity |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| 1   | Every write path is idempotent, or its non-idempotence is documented at the call site with the reason and the compensating action.                                        | Grep the diff for `INSERT`/`UPDATE` reached from a queue handler, webhook, or retryable HTTP verb. Demand a natural key, `ON CONFLICT`, or an explicit `// non-idempotent: <reason>` comment. Test: invoke the handler twice with the same input and assert one row and one side effect. | Blocker  |
| 2   | Any invariant spanning more than one row states its isolation level explicitly and, if `SERIALIZABLE`, ships a bounded retry on serialization failure.                    | Look for multi-statement transactions that read-then-write. Require an explicit `SET TRANSACTION ISOLATION LEVEL` or a documented "single-row, default is fine". A `SERIALIZABLE` block without a `40001` retry is incomplete.                                                           | Blocker  |
| 3   | Schema changes are forward _and_ backward compatible with the currently deployed code (expand/contract, never rename-in-place).                                           | Read the migration next to the code diff. Adding NOT NULL without a default, dropping/renaming a live column, or narrowing a type in one step is a fail. Ask: "if this migration lands and the old pods stay up for 10 minutes, what breaks?"                                            | Blocker  |
| 4   | Every new index names the exact query it serves, in the migration comment.                                                                                                | The migration must contain a comment with the predicate or `ORDER BY` it accelerates. No query named, no index. Verify with `EXPLAIN` output pasted into the MR for the target query.                                                                                                    | Major    |
| 5   | Every list endpoint and every list repository method is paginated with a hard maximum page size.                                                                          | Grep for route handlers returning arrays. Require `limit`/`cursor` params, a server-side clamp (e.g. `min(requested, 100)`), and a default. Unbounded `findAll` on a growing table is a fail.                                                                                            | Blocker  |
| 6   | Every retry is bounded, backed off exponentially, and jittered.                                                                                                           | Search for `retry`, `attempts`, `setTimeout` in workers and HTTP clients. Fixed-interval retries and unbounded loops fail. BullMQ jobs must set `attempts` and `backoff: { type: 'exponential' }`.                                                                                       | Major    |
| 7   | No query without a `LIMIT` or an equality predicate on an indexed column, unless the table is provably bounded.                                                           | Grep raw SQL and query-builder chains for the absence of both. "It's only the settings table" must be written down as the justification.                                                                                                                                                 | Major    |
| 8   | Every cache write states its invalidation strategy (TTL, explicit bust, or version key) in a comment or the caching module.                                               | For each `set`/`setex`, find the corresponding `del` or TTL. A cache with neither is a permanent stale-data bug.                                                                                                                                                                         | Major    |
| 9   | Any operation that writes to Postgres and a second system (queue, search index, third-party API, vector store) uses an outbox or is explicitly documented as best-effort. | Look for `await db.x()` followed by `await queue.add()` in the same function. Either move the enqueue into an outbox row committed with the transaction, or annotate `// best-effort: <what happens if this is lost>`.                                                                   | Blocker  |
| 10  | Deletes and updates in migrations and backfills are batched with a bounded batch size and are resumable.                                                                  | A single `UPDATE` over a whole large table locks it. Require a loop with `LIMIT`, a progress marker, and a way to resume.                                                                                                                                                                | Major    |
| 11  | No cross-node ordering by wall-clock timestamp where correctness depends on the order.                                                                                    | Grep for `ORDER BY created_at` used to decide "latest wins". Require a monotonic sequence, a version column, or an explicit "ties are acceptable" note.                                                                                                                                  | Minor    |
| 12  | Derived data (search index, embeddings, materialized aggregates) has a documented, runnable rebuild path.                                                                 | Ask for the command. If rebuilding requires manual SQL typed by a human at 2am, it does not exist.                                                                                                                                                                                       | Major    |

## Latency and scale budgets

A budget is three numbers and a load parameter, written where the code lives:

```
// budget: p95 < 300ms, p99 < 800ms @ 50 rps, 10k threads/org
```

**How to state one.** Pick the load parameter that actually drives cost for this surface
(requests/sec for an endpoint; jobs/minute and payload size for a worker; documents and
chunks for a RAG pipeline; concurrent threads for the chat hot path). State p95 and p99,
never the mean. State the data-size assumption the budget is valid under — a budget that
holds at 1k rows and not 1M rows is not a budget, it is a snapshot. For anything that
calls an LLM, add a **cost** line (tokens in/out, currency per call) and a **timeout**,
because for LLM-backed paths cost and tail latency are the binding constraints, not CPU.

Suggested starting budgets for this monorepo, to be overridden per surface with evidence:

| Surface                              | Budget                                                      |
| ------------------------------------ | ----------------------------------------------------------- |
| Read endpoint (cached)               | p95 < 100 ms, p99 < 250 ms                                  |
| Read endpoint (uncached, DB)         | p95 < 300 ms, p99 < 800 ms                                  |
| Write endpoint (single transaction)  | p95 < 400 ms, p99 < 1 s                                     |
| Chat turn, first token               | p95 < 1.5 s                                                 |
| Chat turn, complete                  | p95 < 12 s, hard timeout 60 s, cost ceiling per turn stated |
| RAG retrieval (embed + ANN + rerank) | p95 < 400 ms                                                |
| BullMQ job                           | p95 < 5 s; anything longer is chunked into resumable steps  |
| Migration on the largest live table  | < 1 s of exclusive lock, or batched                         |

**How to verify.** In order of cost: (1) `EXPLAIN (ANALYZE, BUFFERS)` on the exact query
with production-shaped row counts, asserting no sequential scan on a growing table and
no unexpected sort; (2) a Vitest integration test seeded to the stated load parameter
that fails when a call exceeds the budget — a slow test is a real test; (3) an OTel span
around the operation with the budget recorded as a span attribute, so the dashboard and
the code cannot disagree; (4) for browser-visible surfaces, a
`performance_start_trace` / `performance_analyze_insight` run via chrome-devtools MCP;
(5) for LLM paths, a Langfuse trace with latency and cost per generation, checked
against the ceiling. A budget with no verification step attached is a comment, not a
budget, and reviewers should say so.

## Applied to Postgres + Redis + BullMQ + vector search

**Transaction boundaries in the repository layer.** The repository is where the
transaction boundary belongs, and it belongs at exactly one level: a public repository
method either owns a transaction or accepts one, never both implicitly. Rules that fall
out of DDIA chapter 7 for our actor-first repositories:

- One logical business operation, one transaction. If a route calls three repository
  methods that must all succeed, the route is wrong: it needs one repository method
  that takes a transaction, or a `withTransaction` wrapper passed down.
- **Never hold a transaction open across an `await` on the network.** An LLM call, an
  HTTP fetch, or a SpiceDB write inside `BEGIN…COMMIT` pins a connection and a snapshot
  for seconds. Compute first, transact last.
- Read-modify-write on a single row uses `UPDATE … SET x = x + 1` or
  `SELECT … FOR UPDATE`, never a read in JS followed by a write — that is the lost
  update, verbatim from the book.
- Cross-row invariants (quota counters, "at most one published version per agent",
  seat limits) get either a database constraint (the strongest option — a partial
  unique index beats any application check) or `SERIALIZABLE` plus a retry. Prefer the
  constraint: it holds even when a future caller forgets the rule.
- Permission checks (SpiceDB) live _outside_ the transaction and are re-verified by a
  database predicate inside it where possible. SpiceDB is eventually consistent; do not
  let a stale allow decision be the only thing standing between a user and a row.

**At-least-once queue semantics and dedup keys.** BullMQ, like every queue worth using,
gives at-least-once delivery: a job can run twice if a worker dies after the side effect
and before the ack, or if a stalled job is recovered. Therefore:

- Give every job a deterministic `jobId` derived from the business key
  (`embed:{documentId}:{version}`), so an accidental double-enqueue collapses to one job.
  That handles duplicate _enqueues_; it does not handle duplicate _executions_.
- Make the handler idempotent for duplicate executions: check-and-set on a
  `processed_jobs` row inside the same transaction as the effect, or write with
  `ON CONFLICT DO NOTHING` on a natural key, or make the operation naturally
  convergent (setting a field to a computed value is idempotent; incrementing is not).
- Set `attempts` and exponential backoff with jitter, and route exhausted jobs to a
  dead-letter queue that a human or an alert actually looks at. A silent failed set is
  data loss with extra steps.
- Never enqueue inside a transaction that might roll back, and never enqueue after a
  commit without accepting that the enqueue can be lost. This is exactly the dual-write
  problem; the outbox is the answer (below).
- Jobs must be resumable. A job that processes 10k chunks and dies at 9k must not
  restart from zero — record progress, or split into per-chunk jobs.

**Outbox, concretely.** Insert a row into an `outbox` table in the same transaction as
the state change. A poller (or logical-decoding consumer) reads unsent rows and enqueues
them, marking them sent. The enqueue is now at-least-once instead of maybe-once, which
combined with idempotent handlers gives effectively-once. Use it wherever losing the
second write is a correctness bug: publishing an agent version, sending an invitation
email, indexing a document, emitting an analytics event that drives billing. Skip it,
with a comment, where losing it is merely annoying.

**Read-aside cache pitfalls (Redis).** Our caching rule already confines read-aside
caching to the chat/conversation hot path; DDIA explains why that restraint is correct.

- The classic race: reader misses, reads DB, writer updates DB and busts the cache,
  reader then writes its now-stale value. Mitigations: short TTLs so the window closes;
  versioned keys (`agent:{id}:v{updatedAtEpoch}`) so a stale value is written to a key
  nobody reads; or write-through for the few keys where staleness is unacceptable.
- Always set a TTL, even when you also bust explicitly. Explicit invalidation will be
  forgotten by exactly one future code path; the TTL is the backstop.
- Cache the _identity_ you intend, not the one you happen to have. Caching by
  `agentId` when the value depends on `(agentId, actorId)` leaks data across tenants —
  this is a security bug, not a performance bug. Every cache key must contain every
  input that varies the value, including the permission scope.
- Guard against stampede on hot keys (single-flight or a short lock), and never cache
  an error or an empty result without a distinct, much shorter TTL.
- Redis is not durable storage. Anything that must survive a Redis flush lives in
  Postgres, and the code must behave correctly with a cold cache — which means there is
  a test that runs with caching disabled.

**Embedding/chunking pipeline reprocessing and versioning.** A vector index is derived
data in the exact sense of DDIA part III, and derived data must be rebuildable.

- Store, on every chunk row: the source document id, the source content hash, the
  chunker version, the embedding model id, and the embedding dimension. Without these
  you cannot answer "which rows are stale?" and you will be forced into a full rebuild
  every time anything changes.
- Model or chunker change = **new version, not in-place update**. Write the new
  embeddings alongside the old under a new `embedding_version`, backfill, flip reads
  behind a feature flag, then drop the old. This is expand/contract applied to vectors,
  and it is the only way to A/B a retrieval change or roll one back.
- Never mix embeddings from two models in one ANN index; cosine distance across models
  is meaningless and the failure is silent — retrieval quality degrades without a single
  error in the logs.
- Re-embedding is idempotent by content hash: `(document_id, chunk_index, content_hash,
embedding_version)` unique. Reprocessing the same document is then free and safe,
  which makes the backfill restartable.
- Deletion must cascade: deleting a document must delete its chunks and vectors in the
  same transaction, or the retrieval layer will serve content the user believes is gone.
  This is a GDPR/EU-AI-Act exposure, not a tidiness issue.
- Backfills are batched, resumable, rate-limited against the embedding provider, and
  costed in advance (chunks × tokens × price). State the number in the MR.
- Quality is derived data too: any retrieval change ships with an offline eval run, and
  the eval gate fails closed when a check did not execute.

## Review prompts

Ten falsifiable questions for any diff touching data. Each must be answerable with
evidence, not opinion.

1. If this handler runs twice with identical input, what is the resulting row count and
   how many side effects fired? Point to the dedup key or the `ON CONFLICT`.
2. Which invariant here spans more than one row, and what isolation level or database
   constraint holds it? If the answer is "the code checks first", where is the retry?
3. Deploy this migration with the previous release still running for ten minutes — name
   the first thing that breaks, or show why nothing does.
4. Which exact query does each new index serve? Paste the `EXPLAIN` before and after.
5. What is the largest number of rows this query can return in production in twelve
   months, and where is the `LIMIT` that caps it?
6. This write touches Postgres and one other system — which one can be lost on crash,
   and is that documented or outboxed?
7. What is this endpoint's p95 budget, at what load, and which test or span verifies it?
8. Every input that varies this cached value — is each one in the cache key, including
   the actor and the tenant? What is the TTL, and what busts it?
9. If Redis is flushed and the LLM provider is returning 503s, what does the user see?
   Show the code path, not the intention.
10. How do I rebuild this derived data from the source of record, as one command, and
    how long does it take at current volume?

## Sources

- Martin Kleppmann, _Designing Data-Intensive Applications_, O'Reilly, 2017 — https://dataintensive.net/
- Kleppmann's notes and errata — https://github.com/ept/ddia-references
- PostgreSQL transaction isolation documentation — https://www.postgresql.org/docs/current/transaction-iso.html
- PostgreSQL indexes and `EXPLAIN` — https://www.postgresql.org/docs/current/using-explain.html
- Martin Fowler, _Transactional Outbox_ / dual-write discussion — https://microservices.io/patterns/data/transactional-outbox.html
- BullMQ documentation on job retries, idempotency and stalled jobs — https://docs.bullmq.io/guide/retrying-failing-jobs
- pgvector — https://github.com/pgvector/pgvector
- AWS Architecture Blog, exponential backoff and jitter — https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
