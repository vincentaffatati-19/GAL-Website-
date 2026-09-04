import { getCurrentSession } from '../auth/session';
import { escapeHtml } from '../render/escape';
import { getSupabaseClient } from '../supabase/client';

export type GolferInsightStatus = 'ACTIVE' | 'ACKNOWLEDGED' | 'RESOLVED' | 'REGRESSED' | 'EVIDENCE_PENDING' | 'INEFFECTIVE' | 'SUPPRESSED' | 'EXPIRED';
export interface GolferInsightRow { id:string; status:GolferInsightStatus; headline:string; golfer_message:string; insight_domain:string; subject_type:string; subject_key:string; scope_key:string; }

const LABELS: Partial<Record<GolferInsightStatus,string>> = {
  ACTIVE:'Needs Attention', ACKNOWLEDGED:'Watching', RESOLVED:'Solved', REGRESSED:'Came Back', EVIDENCE_PENDING:'Checking Progress', INEFFECTIVE:'Still Needs Attention',
};

export function insightLabel(status: GolferInsightStatus): string | null { return LABELS[status] ?? null; }

async function currentGalUserId(): Promise<string | null> {
  const session = await getCurrentSession();
  if (!session) return null;
  const { data } = await getSupabaseClient().from('gal_users').select('id').eq('auth_user_id',session.user.id).single();
  return data?.id ?? null;
}

export async function fetchGolferInsights(): Promise<GolferInsightRow[]> {
  const userId = await currentGalUserId();
  if (!userId) return [];
  const { data,error } = await getSupabaseClient().from('gal_insights')
    .select('id,status,headline,golfer_message,insight_domain,subject_type,subject_key,scope_key')
    .eq('user_id',userId).order('materiality_score',{ascending:false});
  if (error) throw new Error(error.message);
  return (data ?? []) as GolferInsightRow[];
}

export async function renderInsightsSurface(): Promise<string> {
  const rows = await fetchGolferInsights();
  const visible = rows.filter((row) => insightLabel(row.status));
  if (!visible.length) return '<section class="my-gal-state"><h2>No material equipment insights yet.</h2><p>GAL will surface an issue when governed evidence supports it.</p></section>';
  return `<section class="equipment-list">${visible.map((row)=>`<article class="equipment-card"><p class="eyebrow">${escapeHtml(insightLabel(row.status))}</p><h2>${escapeHtml(row.headline)}</h2><p>${escapeHtml(row.golfer_message)}</p></article>`).join('')}</section>`;
}
