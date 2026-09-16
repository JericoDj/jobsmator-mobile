import 'package:flutter/material.dart';

/// A one-shot utility on the Tools tab. Premium tools open the paywall on
/// Free; everything else runs in place.
class Tool {
  const Tool({
    required this.id,
    required this.title,
    required this.blurb,
    required this.icon,
    required this.inputLabel,
    required this.inputHint,
    required this.action,
    this.premium = false,
    this.needsResume = false,
  });

  final String id, title, blurb, inputLabel, inputHint, action;
  final IconData icon;
  final bool premium, needsResume;
}

const tools = [
  Tool(
    id: 'resume-analyzer',
    title: 'Resume Analyzer',
    blurb: 'What recruiters see first, and what to fix.',
    icon: Icons.description_outlined,
    inputLabel: 'Target role (optional)',
    inputHint: 'Senior Flutter Developer',
    action: 'Analyze my resume',
    needsResume: true,
  ),
  Tool(
    id: 'cover-letter',
    title: 'Cover Letter Generator',
    blurb: 'A one-page letter in your voice, from the job post.',
    icon: Icons.mail_outline_rounded,
    inputLabel: 'Paste the job description',
    inputHint: 'We are looking for a Flutter developer who…',
    action: 'Write the letter',
    premium: true,
    needsResume: true,
  ),
  Tool(
    id: 'application-email',
    title: 'Application Email',
    blurb: 'Short, specific, and easy to reply to.',
    icon: Icons.send_outlined,
    inputLabel: 'Job title and company',
    inputHint: 'Flutter Developer at Maya',
    action: 'Draft the email',
    needsResume: true,
  ),
  Tool(
    id: 'job-match',
    title: 'Job Match Analyzer',
    blurb: 'Score one listing against your resume, with reasons.',
    icon: Icons.track_changes_rounded,
    inputLabel: 'Paste the job description or link',
    inputHint: 'https://www.linkedin.com/jobs/view/…',
    action: 'Score this job',
    needsResume: true,
  ),
  Tool(
    id: 'salary',
    title: 'Salary Analyzer',
    blurb: 'A realistic range for the role, level and city.',
    icon: Icons.payments_outlined,
    inputLabel: 'Role, level and location',
    inputHint: 'Mid-level Flutter Developer, Manila, remote',
    action: 'Estimate the range',
    premium: true,
  ),
  Tool(
    id: 'resume-builder',
    title: 'Resume Builder',
    blurb: 'Rebuild your resume around one target role.',
    icon: Icons.auto_fix_high_outlined,
    inputLabel: 'Target role',
    inputHint: 'Mobile Engineer',
    action: 'Build a draft',
    premium: true,
    needsResume: true,
  ),
  Tool(
    id: 'interview-prep',
    title: 'Interview Prep',
    blurb: 'Likely questions and strong answers, from the listing.',
    icon: Icons.record_voice_over_outlined,
    inputLabel: 'Job title or paste the listing',
    inputHint: 'Senior Flutter Developer at Sprout',
    action: 'Prepare me',
    needsResume: true,
  ),
  Tool(
    id: 'jd-analyzer',
    title: 'Job Description Analyzer',
    blurb: 'Red flags, must-haves and what they actually want.',
    icon: Icons.manage_search_rounded,
    inputLabel: 'Paste the job description',
    inputHint: 'Responsibilities: …',
    action: 'Analyze the listing',
  ),
];

Tool? toolById(String id) => tools.where((t) => t.id == id).firstOrNull;
