  .post(
    "/:id/score",
    route({
      tag: "Jobs",
      summary: "Score a job for the current user",
      description: "Recalculates fit using OpenRouter, consumes 1 credit, creates a new job record for this user if it's from the feed.",
      ok: { schema: Job },
      errors: { 404: "Unknown job" }
    }),
    validator("param", IdParam),
    async (c) => {
      const user = c.get("user");
      const id = c.req.valid("param").id;
      
      if (!env.OPENROUTER_API_KEY) throw new ApiError("engine_unavailable", "OpenRouter API key is not configured.");

      // Check run limits
      const isPro = user.plan === "pro";
      const searchLimit = isPro ? 5 : 1;
      const periodLabel = isPro ? "this hour" : "today";
      const periodMs = isPro ? 60 * 60 * 1000 : 24 * 60 * 60 * 1000;
      const since = new Date(Date.now() - periodMs);

      const [recentRow] = await db
        .select({ recent: dsql<number>`count(*)::int` })
        .from(runs)
        .where(and(eq(runs.userId, user.id), gt(runs.startedAt, since)));
        
      if ((recentRow?.recent ?? 0) >= searchLimit) {
        throw new ApiError("too_many_runs", `You've used ${searchLimit} searches ${periodLabel}. Upgrade or try again later.`);
      }

      // Find the job being requested
      const [sourceJob] = await db.select().from(jobs).where(eq(jobs.id, id));
      if (!sourceJob) throw new ApiError("not_found", "That job is no longer here.");

      // Fetch user's latest resume profile
      const [resume] = await db.select().from(resumes).where(eq(resumes.userId, user.id)).orderBy(desc(resumes.createdAt)).limit(1);
      if (!resume || !resume.profile) throw new ApiError("invalid_request", "You need to upload a resume first.");
      
      const interests = (user.defaults as any).interests || [];

      const prompt = `You are an expert AI recruiting assistant. 
Score this job posting against the user's career profile and interests.
Output ONLY a JSON object with this exact schema:
{
  "score": number (0-100),
  "tier": "strong" | "good" | "skip",
  "why": string (short explanation of why it fits or doesn't, address the user directly as 'you'),
  "redFlags": string[] (any concerning things, e.g., 'requires 10 years experience but you have 2', empty array if none)
}

USER PROFILE:
${JSON.stringify(resume.profile, null, 2)}
USER JOB INTERESTS:
${interests.join(", ")}

JOB POSTING:
Title: ${sourceJob.title}
Company: ${sourceJob.company}
Remote: ${sourceJob.remote}
Location: ${sourceJob.location}
Summary/Why: ${sourceJob.why}
`;

      let aiRes;
      try {
        const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${env.OPENROUTER_API_KEY}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            model: "openai/gpt-4o-mini",
            response_format: { type: "json_object" },
            messages: [{ role: "user", content: prompt }]
          })
        });
        if (!response.ok) throw new Error("OpenRouter API error");
        const data = (await response.json()) as any;
        aiRes = JSON.parse(data.choices[0].message.content);
      } catch (err) {
        throw new ApiError("engine_unavailable", "Failed to score job.");
      }

      // Charge 1 credit by inserting a dummy run
      const [run] = await db.insert(runs).values({ 
        userId: user.id, 
        resumeId: resume.id, 
        request: { job_interests: interests, jobsites: ["jobsmator"], jobs_per_site: 1, resume_url: resume.url! },
        status: "finished",
        stats: { jobsFound: 1, matches: 1 }
      }).returning();

      // Create new job row for this user
      const [newJob] = await db.insert(jobs).values({
        runId: run.id,
        userId: user.id,
        fingerprint: sourceJob.fingerprint,
        rank: sourceJob.rank,
        score: aiRes.score,
        tier: aiRes.score >= 70 ? "strong" : aiRes.score >= 60 ? "good" : "skip",
        title: sourceJob.title,
        company: sourceJob.company,
        location: sourceJob.location,
        remote: sourceJob.remote,
        salary: sourceJob.salary,
        postedAt: sourceJob.postedAt,
        url: sourceJob.url,
        site: sourceJob.site,
        matchedInterest: interests[0] || "Custom",
        why: aiRes.why || "",
        redFlags: aiRes.redFlags || [],
      }).returning();

      return c.json(toJob(newJob as any));
    }
  )
