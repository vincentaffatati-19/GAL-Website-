(function () {
  'use strict';

  const SOURCE_TOOL = 'driver_buyers_guide';
  const SOURCE_TOOL_VERSION = '0.2-rc15';
  let lastRecommendationSignature = null;

  function guideApi() {
    return window.GAL_DRIVER_GUIDE_API || null;
  }

  function buildBagPayload({ product, scored, state, recommendationRank }) {
    if (!product || !product.id) throw new Error('CANONICAL_DRIVER_REQUIRED');
    state = state || {};
    scored = scored || {};
    return {
      itemType: 'CLUB',
      category: 'DRIVER',
      slotCode: 'D',
      slotLabel: 'Driver',
      canonicalProductId: product.id,
      canonicalBrandId: product.brandId || null,
      display: { brand: product.brand, model: product.model, year: product.year },
      configuration: { selectedLoftDeg: null, handedness: null },
      status: 'IN_BAG',
      countsToward14: true,
      sourceTool: SOURCE_TOOL,
      sourceToolVersion: SOURCE_TOOL_VERSION,
      marketCode: state.market || 'US',
      recommendation: {
        fit: Number.isFinite(scored.fit) ? scored.fit : null,
        value: Number.isFinite(scored.value) ? scored.value : null,
        reasons: Array.isArray(scored.reasons) ? scored.reasons.slice() : [],
        rank: recommendationRank == null ? null : recommendationRank,
        inputs: {
          audience: state.audience ?? null,
          speed: state.speed ?? null,
          miss: state.miss ?? null,
          flight: state.flight ?? null,
          goal: state.goal ?? null,
          budget: state.budget ?? null,
          market: state.market ?? null
        }
      }
    };
  }

  function toRemotePayload(payload) {
    return {
      canonicalProductId: payload.canonicalProductId,
      status: payload.status,
      displaySnapshot: payload.display,
      configuration: payload.configuration,
      components: [{
        slotCode: payload.slotCode,
        slotLabel: payload.slotLabel,
        clubCount: 1,
        configuration: payload.configuration
      }],
      decision: {
        sourceTool: payload.sourceTool,
        sourceToolVersion: payload.sourceToolVersion,
        recommendationRank: payload.recommendation.rank,
        userInputs: payload.recommendation.inputs,
        metrics: { fit: payload.recommendation.fit, value: payload.recommendation.value },
        reasonSummary: payload.recommendation.reasons.join(' | ') || null,
        marketCode: payload.marketCode
      }
    };
  }

  function resolveScored(canonicalId) {
    const api = guideApi();
    if (!api) return null;
    return (api.getResults ? api.getResults() : []).find(row => String(row.id) === String(canonicalId)) || null;
  }

  function resolveProduct(canonicalId) {
    const api = guideApi();
    if (!api || !Array.isArray(api.data)) return null;
    return api.data.find(row => String(row.id) === String(canonicalId)) || null;
  }

  function recommendationRank(canonicalId) {
    const api = guideApi();
    if (!api || !api.getResults) return null;
    const index = api.getResults().findIndex(row => String(row.id) === String(canonicalId));
    return index < 0 ? null : index + 1;
  }

  async function refreshBagWarnings() {
    const client = window.GALRemote?.ready?.();
    if (!client || typeof client.rpc !== 'function') return { ok: false, code: 'REMOTE_NOT_READY', warnings: [] };
    const { data, error } = await client.rpc('gal_my_bag_warnings');
    if (error) return { ok: false, code: 'WARNING_REFRESH_FAILED', error, warnings: [] };
    return { ok: true, ...(data || {}), warnings: Array.isArray(data?.warnings) ? data.warnings : [] };
  }

  async function resolveActiveBagInternalId(client) {
    if (!client || typeof client.from !== 'function') return { ok: false, code: 'ACTIVE_BAG_LOOKUP_UNAVAILABLE', bagId: null };
    const query = client.from('gal_bags')
      .select('id,bag_id')
      .eq('is_active', true)
      .limit(1);
    if (!query || typeof query.maybeSingle !== 'function') return { ok: false, code: 'ACTIVE_BAG_LOOKUP_UNAVAILABLE', bagId: null };
    const { data, error } = await query.maybeSingle();
    if (error) return { ok: false, code: 'ACTIVE_BAG_LOOKUP_FAILED', error, bagId: null };
    if (!data) return { ok: true, bagId: null, publicBagId: null };
    if (!data.id) return { ok: false, code: 'ACTIVE_BAG_INTERNAL_ID_MISSING', bagId: null, publicBagId: data.bag_id || null };
    return { ok: true, bagId: data.id, publicBagId: data.bag_id || null };
  }

  async function checkSlotConflicts(slotCode) {
    const client = window.GALRemote?.ready?.();
    if (!client || typeof client.rpc !== 'function') return { ok: false, code: 'REMOTE_NOT_READY', conflicts: [] };
    const activeBag = await resolveActiveBagInternalId(client);
    if (!activeBag.ok) return { ...activeBag, conflicts: [] };
    if (!activeBag.bagId) return { ok: true, bagId: null, publicBagId: null, conflicts: [] };
    const { data, error } = await client.rpc('gal_slot_conflicts', { p_bag_id: activeBag.bagId, p_slots: [slotCode] });
    if (error) return { ok: false, code: 'SLOT_CONFLICT_CHECK_FAILED', error, bagId: activeBag.bagId, publicBagId: activeBag.publicBagId, conflicts: [] };
    return { ok: true, bagId: activeBag.bagId, publicBagId: activeBag.publicBagId, conflicts: Array.isArray(data) ? data : [] };
  }

  async function addToBag(canonicalId) {
    const api = guideApi();
    const product = resolveProduct(canonicalId);
    const scored = resolveScored(canonicalId);
    if (!api || !product || !scored) return { ok: false, code: 'DRIVER_NOT_FOUND' };
    const payload = buildBagPayload({
      product,
      scored,
      state: api.state || {},
      recommendationRank: recommendationRank(canonicalId)
    });

    let user = null;
    if (typeof window.GALRemote?.getSessionUser === 'function') {
      try { user = await window.GALRemote.getSessionUser(); } catch (_) { user = null; }
    }

    if (user) {
      const client = window.GALRemote?.ready?.();
      if (!client || typeof client.rpc !== 'function') return { ok: false, code: 'REMOTE_NOT_READY' };
      const conflictState = await checkSlotConflicts('D');
      if (!conflictState.ok) return conflictState;
      if (conflictState.conflicts.length) {
        return { ok: false, code: 'SLOT_CONFLICT', conflicts: conflictState.conflicts, bagId: conflictState.bagId };
      }
      const { data, error } = await client.rpc('gal_add_to_my_bag', { p_payload: toRemotePayload(payload) });
      if (error || !data?.ok) return { ok: false, code: 'REMOTE_ADD_FAILED', error: error || null, data: data || null };
      const warningState = await refreshBagWarnings();
      await window.GALIntelligence?.emit?.('product_added_to_bag', 'Driver', {
        canonical_product_id: product.id,
        metadata: { source_tool: SOURCE_TOOL, source_tool_version: SOURCE_TOOL_VERSION, fit: scored.fit, value: scored.value }
      });
      return { ...data, ok: true, local: false, warningState };
    }

    const local = window.GALMyBag;
    let saved = false;
    if (typeof local?.addDriver === 'function') saved = await local.addDriver(payload);
    else if (typeof local?.addItem === 'function') saved = await local.addItem(payload);
    else if (typeof local?.add === 'function') saved = await local.add(payload);
    else return { ok: false, code: 'LOCAL_BAG_API_UNAVAILABLE' };

    if (!saved) return { ok: false, code: 'LOCAL_ADD_FAILED' };
    return { ok: true, local: true, payload };
  }

  async function emitCompared(canonicalId, isSelected, selectedCount) {
    if (!isSelected) return { ok: true, emitted: false };
    const product = resolveProduct(canonicalId);
    const scored = resolveScored(canonicalId);
    if (!product || !scored) return { ok: false, emitted: false, code: 'DRIVER_NOT_FOUND' };
    if (typeof window.GALIntelligence?.emit !== 'function') return { ok: true, emitted: false, code: 'INTELLIGENCE_UNAVAILABLE' };
    await window.GALIntelligence.emit('product_compared', 'Driver', {
      canonical_product_id: product.id,
      metadata: {
        source_tool: SOURCE_TOOL,
        source_tool_version: SOURCE_TOOL_VERSION,
        fit: scored.fit,
        value: scored.value,
        compare_count: selectedCount
      }
    });
    return { ok: true, emitted: true };
  }

  async function emitRecommendationSnapshot() {
    const api = guideApi();
    if (!api || typeof api.getResults !== 'function') return { ok: false, emitted: false, code: 'GUIDE_NOT_READY' };
    const top = api.getResults().slice(0, 9);
    const snapshot = {
      inputs: {
        audience: api.state?.audience ?? null,
        speed: api.state?.speed ?? null,
        miss: api.state?.miss ?? null,
        flight: api.state?.flight ?? null,
        goal: api.state?.goal ?? null,
        budget: api.state?.budget ?? null,
        market: api.state?.market ?? null
      },
      top: top.map(x => [x.id, x.fit, x.value])
    };
    const signature = JSON.stringify(snapshot);
    if (signature === lastRecommendationSignature) return { ok: true, emitted: false, deduped: true };
    lastRecommendationSignature = signature;
    if (typeof window.GALIntelligence?.emit !== 'function') return { ok: true, emitted: false, code: 'INTELLIGENCE_UNAVAILABLE' };
    await window.GALIntelligence.emit('recommendation_generated', 'Driver', {
      metadata: {
        source_tool: SOURCE_TOOL,
        source_tool_version: SOURCE_TOOL_VERSION,
        inputs: snapshot.inputs,
        top: top.map((x, index) => ({ id: x.id, rank: index + 1, fit: x.fit, value: x.value, reasons: x.reasons || [] }))
      }
    });
    return { ok: true, emitted: true };
  }

  window.GALDriverRC15 = Object.freeze({
    buildBagPayload,
    addToBag,
    emitCompared,
    emitRecommendationSnapshot,
    refreshBagWarnings
  });

  Promise.resolve().then(async function () {
    try {
      if (typeof window.GALIntelligence?.init === 'function') await window.GALIntelligence.init();
      if (typeof window.GALIntelligence?.emit === 'function') {
        await window.GALIntelligence.emit('guide_started', 'Driver', {
          metadata: { source_tool: SOURCE_TOOL, source_tool_version: SOURCE_TOOL_VERSION }
        });
      }
    } catch (error) {
      console.error('GAL Driver guide-start event failed', error);
    }
  });
})();
