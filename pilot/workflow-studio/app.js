(() => {
  "use strict";

  const state = {
    catalog: null,
    etag: "",
    savedJson: "",
    workflow: {
      workflowId: "generic.review",
      version: "1.0.0",
      status: "draft",
      displayName: "Generic review",
      ownerRole: "workflowAdministrator",
      dataClassification: "internal",
      entryNodeId: "",
      nodes: [],
      transitions: [],
      metadata: { referenceUi: true }
    }
  };

  const byId = (id) => document.getElementById(id);

  const text = (value) => typeof value === "string" ? value : "";

  function nodeType(type) {
    return state.catalog?.nodeTypes?.find((item) => item.type === type) || null;
  }

  function uniqueNodeId(type) {
    const stem = type.replaceAll("_", "-");
    let index = 1;
    let candidate = stem;
    const ids = new Set(state.workflow.nodes.map((node) => node.id));
    while (ids.has(candidate)) {
      index += 1;
      candidate = `${stem}-${index}`;
    }
    return candidate;
  }

  function defaultConfig(meta) {
    const config = {};
    for (const field of meta.fields || []) {
      if (field.control === "toggle") {
        config[field.key] = field.key === "humanReviewRequired";
      } else if (field.control === "number") {
        config[field.key] = field.required ? 1 : 0;
      } else if (Array.isArray(field.options) && field.options.length > 0) {
        config[field.key] = field.options[0];
      } else {
        config[field.key] = "";
      }
    }
    return config;
  }

  function addNode(type) {
    const meta = nodeType(type);
    if (!meta || meta.availability !== "supported") {
      return;
    }
    const id = uniqueNodeId(type);
    state.workflow.nodes.push({
      id,
      type,
      displayName: meta.displayName,
      config: defaultConfig(meta)
    });
    if (!state.workflow.entryNodeId) {
      state.workflow.entryNodeId = id;
    }
    render();
  }

  function removeNode(id) {
    state.workflow.nodes = state.workflow.nodes.filter((node) => node.id !== id);
    state.workflow.transitions = state.workflow.transitions.filter(
      (edge) => edge.from !== id && edge.to !== id
    );
    if (state.workflow.entryNodeId === id) {
      state.workflow.entryNodeId = state.workflow.nodes[0]?.id || "";
    }
    render();
  }

  function updateNodeId(oldId, nextId) {
    const next = nextId.trim();
    const node = state.workflow.nodes.find((item) => item.id === oldId);
    if (!node || !next) {
      return;
    }
    node.id = next;
    for (const edge of state.workflow.transitions) {
      if (edge.from === oldId) edge.from = next;
      if (edge.to === oldId) edge.to = next;
    }
    if (state.workflow.entryNodeId === oldId) {
      state.workflow.entryNodeId = next;
    }
    render();
  }

  function renderPalette() {
    const palette = byId("palette");
    palette.replaceChildren();
    for (const meta of state.catalog?.nodeTypes || []) {
      const item = document.createElement("div");
      item.className = "palette-item";
      const heading = document.createElement("div");
      heading.innerHTML = `<strong>${meta.displayName}</strong> <span class="badge">${meta.availability}</span>`;
      const button = document.createElement("button");
      button.type = "button";
      button.textContent = meta.availability === "supported" ? "Add" : "Reserved";
      button.disabled = meta.availability !== "supported";
      button.addEventListener("click", () => addNode(meta.type));
      item.append(heading, button);
      palette.append(item);
    }
  }

  function makeField(node, field) {
    const wrapper = document.createElement("label");
    wrapper.className = "field-label";
    const caption = document.createElement("span");
    caption.textContent = field.label + (field.required ? " *" : "");
    let input;

    if (field.control === "toggle") {
      input = document.createElement("input");
      input.type = "checkbox";
      input.checked = Boolean(node.config[field.key]);
      input.addEventListener("change", () => {
        node.config[field.key] = input.checked;
        refreshValidationAndJson();
      });
    } else if (field.control === "select" && Array.isArray(field.options)) {
      input = document.createElement("select");
      for (const option of field.options) {
        const el = document.createElement("option");
        el.value = option;
        el.textContent = option;
        input.append(el);
      }
      input.value = text(node.config[field.key]);
      input.addEventListener("change", () => {
        node.config[field.key] = input.value;
        refreshValidationAndJson();
      });
    } else {
      input = document.createElement("input");
      input.type = field.control === "number" ? "number" : "text";
      input.value = field.control === "number"
        ? String(node.config[field.key] ?? "")
        : text(node.config[field.key]);
      input.placeholder = field.control;
      input.addEventListener("input", () => {
        node.config[field.key] = field.control === "number"
          ? Number(input.value)
          : input.value;
        refreshValidationAndJson();
      });
    }

    input.dataset.governanceClass = field.governanceClass;
    wrapper.append(caption, input);
    return wrapper;
  }

  function renderNodes() {
    const host = byId("nodes");
    host.replaceChildren();
    byId("nodeCount").textContent = `${state.workflow.nodes.length} node(s)`;

    for (const node of state.workflow.nodes) {
      const meta = nodeType(node.type);
      const card = document.createElement("article");
      card.className = "node-card";

      const heading = document.createElement("div");
      heading.className = "node-heading";
      const title = document.createElement("div");
      title.innerHTML = `<strong>${node.displayName}</strong> <span class="badge">${node.type}</span>`;
      const remove = document.createElement("button");
      remove.type = "button";
      remove.textContent = "Remove";
      remove.addEventListener("click", () => removeNode(node.id));
      heading.append(title, remove);

      const basics = document.createElement("div");
      basics.className = "node-fields";

      const idLabel = document.createElement("label");
      idLabel.innerHTML = "<span>Node ID *</span>";
      const idInput = document.createElement("input");
      idInput.value = node.id;
      idInput.addEventListener("change", () => updateNodeId(node.id, idInput.value));
      idLabel.append(idInput);

      const nameLabel = document.createElement("label");
      nameLabel.innerHTML = "<span>Display name *</span>";
      const nameInput = document.createElement("input");
      nameInput.value = node.displayName;
      nameInput.addEventListener("input", () => {
        node.displayName = nameInput.value;
        refreshValidationAndJson();
      });
      nameLabel.append(nameInput);

      basics.append(idLabel, nameLabel);

      if (meta) {
        for (const field of meta.fields || []) {
          basics.append(makeField(node, field));
        }
      }

      card.append(heading, basics);
      host.append(card);
    }
  }

  function nodeOptions(selected) {
    const fragment = document.createDocumentFragment();
    const blank = document.createElement("option");
    blank.value = "";
    blank.textContent = "Select…";
    fragment.append(blank);
    for (const node of state.workflow.nodes) {
      const option = document.createElement("option");
      option.value = node.id;
      option.textContent = node.id;
      option.selected = node.id === selected;
      fragment.append(option);
    }
    return fragment;
  }

  function renderTransitions() {
    const host = byId("transitions");
    host.replaceChildren();
    state.workflow.transitions.forEach((edge, index) => {
      const row = document.createElement("div");
      row.className = "transition-row";

      const fromLabel = document.createElement("label");
      fromLabel.innerHTML = "<span>From</span>";
      const from = document.createElement("select");
      from.append(nodeOptions(edge.from));
      from.addEventListener("change", () => {
        edge.from = from.value;
        refreshValidationAndJson();
      });
      fromLabel.append(from);

      const toLabel = document.createElement("label");
      toLabel.innerHTML = "<span>To</span>";
      const to = document.createElement("select");
      to.append(nodeOptions(edge.to));
      to.addEventListener("change", () => {
        edge.to = to.value;
        refreshValidationAndJson();
      });
      toLabel.append(to);

      const labelWrap = document.createElement("label");
      labelWrap.innerHTML = "<span>Route label</span>";
      const label = document.createElement("input");
      label.value = edge.label || "";
      label.addEventListener("input", () => {
        edge.label = label.value;
        refreshValidationAndJson();
      });
      labelWrap.append(label);

      const remove = document.createElement("button");
      remove.type = "button";
      remove.textContent = "Remove";
      remove.addEventListener("click", () => {
        state.workflow.transitions.splice(index, 1);
        render();
      });

      row.append(fromLabel, toLabel, labelWrap, remove);
      host.append(row);
    });
  }

  function renderMetadata() {
    byId("workflowId").value = state.workflow.workflowId || "";
    byId("workflowVersion").value = state.workflow.version || "";
    byId("workflowName").value = state.workflow.displayName || "";
    byId("ownerRole").value = state.workflow.ownerRole || "";
    byId("classification").value = state.workflow.dataClassification || "internal";

    const entry = byId("entryNode");
    entry.replaceChildren();
    entry.append(nodeOptions(state.workflow.entryNodeId));
    entry.value = state.workflow.entryNodeId || "";
  }

  function validate() {
    const errors = [];
    const ids = state.workflow.nodes.map((node) => node.id);

    if (!state.workflow.workflowId.trim()) errors.push("Workflow ID is required.");
    if (!state.workflow.version.trim()) errors.push("Version is required.");
    if (!state.workflow.displayName.trim()) errors.push("Display name is required.");
    if (ids.length === 0) errors.push("At least one node is required.");
    if (new Set(ids).size !== ids.length) errors.push("Node IDs must be unique.");
    if (!ids.includes(state.workflow.entryNodeId)) errors.push("Entry node must reference an existing node.");
    if (!state.workflow.nodes.some((node) => node.type === "end")) errors.push("At least one end node is required.");

    const outgoing = new Map(ids.map((id) => [id, []]));
    const indegree = new Map(ids.map((id) => [id, 0]));

    for (const node of state.workflow.nodes) {
      const meta = nodeType(node.type);
      if (!meta) {
        errors.push(`Node ${node.id} has an unknown type.`);
      } else if (meta.availability !== "supported") {
        errors.push(`Node ${node.id} uses reserved type ${node.type}.`);
      }
      if (!node.id.trim()) errors.push("Node IDs cannot be blank.");
      if (!node.displayName.trim()) errors.push(`Node ${node.id || "(blank)"} needs a display name.`);
      if (node.type === "agent") {
        if (node.config.humanReviewRequired !== true) {
          errors.push(`Agent node ${node.id} must require human review.`);
        }
        if (node.config.failureMode !== "ordinary-human-path") {
          errors.push(`Agent node ${node.id} must preserve the ordinary human path.`);
        }
      }
      if ((node.type === "human_review" || node.type === "approval") && !text(node.config.assignedRole).trim()) {
        errors.push(`Human node ${node.id} requires an assigned role.`);
      }
    }

    for (const edge of state.workflow.transitions) {
      if (!ids.includes(edge.from) || !ids.includes(edge.to)) {
        errors.push("Every transition must reference existing nodes.");
        continue;
      }
      if (edge.from === edge.to) {
        errors.push(`Self-loop at ${edge.from} is not allowed.`);
      }
      outgoing.get(edge.from).push(edge.to);
      indegree.set(edge.to, indegree.get(edge.to) + 1);
    }

    for (const node of state.workflow.nodes) {
      const edges = outgoing.get(node.id) || [];
      if (node.type === "end" && edges.length > 0) {
        errors.push(`End node ${node.id} cannot have outgoing transitions.`);
      }
      if (node.type !== "end" && edges.length === 0) {
        errors.push(`Node ${node.id} requires an outgoing transition.`);
      }
    }

    const queue = ids.filter((id) => indegree.get(id) === 0);
    let processed = 0;
    while (queue.length > 0) {
      const current = queue.pop();
      processed += 1;
      for (const target of outgoing.get(current) || []) {
        indegree.set(target, indegree.get(target) - 1);
        if (indegree.get(target) === 0) queue.push(target);
      }
    }
    if (ids.length > 0 && processed !== ids.length) {
      errors.push("Cycles are not supported until bounded-loop semantics are implemented.");
    }

    if (ids.includes(state.workflow.entryNodeId)) {
      const seen = new Set();
      const stack = [state.workflow.entryNodeId];
      while (stack.length > 0) {
        const current = stack.pop();
        if (seen.has(current)) continue;
        seen.add(current);
        stack.push(...(outgoing.get(current) || []));
      }
      if (seen.size !== ids.length) {
        errors.push("Every node must be reachable from the entry node.");
      }
    }

    return [...new Set(errors)];
  }

  function renderValidation() {
    const host = byId("validation");
    const errors = validate();
    host.replaceChildren();
    if (errors.length === 0) {
      const ok = document.createElement("div");
      ok.className = "validation-ok";
      ok.textContent = "Draft passes client-side structural and semantic checks.";
      host.append(ok);
      return true;
    }
    for (const error of errors) {
      const item = document.createElement("div");
      item.className = "validation-error";
      item.textContent = "• " + error;
      host.append(item);
    }
    return false;
  }

  function cleanWorkflow() {
    const workflow = structuredClone(state.workflow);
    for (const edge of workflow.transitions) {
      if (!edge.label) delete edge.label;
    }
    return workflow;
  }

  function renderJson() {
    byId("jsonOutput").value = JSON.stringify(cleanWorkflow(), null, 2);
  }

  function refreshValidationAndJson() {
    renderValidation();
    renderJson();
  }

  function render() {
    renderMetadata();
    renderPalette();
    renderNodes();
    renderTransitions();
    refreshValidationAndJson();
  }

  function bindMetadata() {
    const bindings = [
      ["workflowId", "workflowId"],
      ["workflowVersion", "version"],
      ["workflowName", "displayName"],
      ["ownerRole", "ownerRole"],
      ["classification", "dataClassification"]
    ];
    for (const [elementId, key] of bindings) {
      byId(elementId).addEventListener("input", (event) => {
        state.workflow[key] = event.target.value;
        refreshValidationAndJson();
      });
    }
    byId("entryNode").addEventListener("change", (event) => {
      state.workflow.entryNodeId = event.target.value;
      refreshValidationAndJson();
    });
  }

  async function loadCatalog() {
    const response = await fetch("../../config/workflow-editor-catalog.example.json", { cache: "no-store" });
    if (!response.ok) {
      throw new Error(`Catalogue request failed: ${response.status}`);
    }
    const catalog = await response.json();
    if (catalog.schemaVersion !== 1 || !Array.isArray(catalog.nodeTypes)) {
      throw new Error("Catalogue contract is invalid.");
    }
    state.catalog = catalog;
    byId("catalogStatus").textContent = `Catalogue v${catalog.schemaVersion}: ${catalog.nodeTypes.length} node types`;
  }

  async function loadSample() {
    const response = await fetch("sample.workflow.json", { cache: "no-store" });
    if (!response.ok) throw new Error("Sample workflow could not be loaded.");
    state.workflow = await response.json();
  }

  function loadFromTextarea() {
    try {
      const parsed = JSON.parse(byId("jsonOutput").value);
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
        throw new Error("Workflow JSON must be an object.");
      }
      parsed.status = "draft";
      state.workflow = parsed;
      state.etag = "";
      state.savedJson = "";
      updateEtag();
      render();
      setApiStatus("Loaded draft from JSON.");
    } catch (error) {
      setApiStatus(`JSON load failed: ${error.message}`);
    }
  }

  function apiBase() {
    return byId("apiBase").value.trim().replace(/\/$/, "");
  }

  function versionUrl() {
    const base = apiBase();
    if (!base) throw new Error("API base URL is required.");
    return `${base}/api/v1/workflows/${encodeURIComponent(state.workflow.workflowId)}/versions/${encodeURIComponent(state.workflow.version)}`;
  }

  function validationUrl() {
    return versionUrl() + "/validate";
  }

  function setApiStatus(message) {
    byId("apiStatus").textContent = message;
  }

  function updateEtag() {
    byId("etagStatus").textContent = "ETag: " + (state.etag || "none");
  }

  async function loadFromApi() {
    try {
      const response = await fetch(versionUrl(), { headers: { Accept: "application/json" } });
      if (!response.ok) throw new Error(`GET failed with HTTP ${response.status}`);
      const record = await response.json();
      state.workflow = record.definition;
      state.etag = response.headers.get("ETag") || record.etag || "";
      state.savedJson = JSON.stringify(cleanWorkflow());
      updateEtag();
      render();
      setApiStatus(`Loaded ${record.workflowId} ${record.version} (${record.state}).`);
    } catch (error) {
      setApiStatus(`API load failed: ${error.message}`);
    }
  }

  async function saveDraft() {
    try {
      state.workflow.status = "draft";
      if (!renderValidation()) {
        throw new Error("Draft has validation errors.");
      }
      const headers = { "Content-Type": "application/json", Accept: "application/json" };
      if (state.etag) headers["If-Match"] = state.etag;
      const response = await fetch(versionUrl(), {
        method: "PUT",
        headers,
        body: JSON.stringify(cleanWorkflow())
      });
      if (!response.ok) {
        const detail = await response.text();
        throw new Error(`PUT failed with HTTP ${response.status}${detail ? ": " + detail : ""}`);
      }
      const record = await response.json();
      state.workflow = record.definition;
      state.etag = response.headers.get("ETag") || record.etag || "";
      state.savedJson = JSON.stringify(cleanWorkflow());
      updateEtag();
      render();
      setApiStatus(`Saved draft revision ${record.revision}.`);
    } catch (error) {
      setApiStatus(`API save failed: ${error.message}`);
    }
  }

  async function validateWithApi() {
    try {
      const currentJson = JSON.stringify(cleanWorkflow());
      if (!state.savedJson || currentJson !== state.savedJson) {
        throw new Error("Save or reload this draft before authoritative validation; unsaved changes are not sent to the validation endpoint.");
      }
      const response = await fetch(validationUrl(), {
        method: "POST",
        headers: { Accept: "application/json" }
      });
      if (!response.ok) {
        const detail = await response.text();
        throw new Error(`POST validate failed with HTTP ${response.status}${detail ? ": " + detail : ""}`);
      }
      const result = await response.json();
      if (
        typeof result.deployable !== "boolean" ||
        !Array.isArray(result.errors) ||
        typeof result.definitionHash !== "string"
      ) {
        throw new Error("Validation response does not match the expected contract.");
      }
      const lines = [
        `Server validation: ${result.deployable ? "deployable" : "blocked"}`,
        `Definition hash: ${result.definitionHash}`
      ];
      if (result.errors.length > 0) {
        lines.push(...result.errors.map((error) => `- ${error}`));
      }
      setApiStatus(lines.join("\n"));
    } catch (error) {
      setApiStatus(`API validation failed: ${error.message}`);
    }
  }

  function bindActions() {
    byId("addTransition").addEventListener("click", () => {
      const first = state.workflow.nodes[0]?.id || "";
      state.workflow.transitions.push({ from: first, to: first, label: "" });
      render();
    });
    byId("refreshJson").addEventListener("click", refreshValidationAndJson);
    byId("loadJson").addEventListener("click", loadFromTextarea);
    byId("loadApi").addEventListener("click", loadFromApi);
    byId("saveApi").addEventListener("click", saveDraft);
    byId("validateApi").addEventListener("click", validateWithApi);
  }

  async function start() {
    bindMetadata();
    bindActions();
    try {
      await loadCatalog();
      await loadSample();
      updateEtag();
      render();
      setApiStatus("Reference editor ready. Drafts are not published from this surface.");
    } catch (error) {
      byId("catalogStatus").textContent = "Editor initialization failed.";
      setApiStatus(error.message);
    }
  }

  start();
})();
