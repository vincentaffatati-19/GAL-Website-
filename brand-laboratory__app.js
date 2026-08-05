(()=>{
  "use strict";

  function initBrandLaboratory(){
    const root=document.querySelector(".brand-lab");
    if(!root) return;

    const DB=window.GAL_BRAND_DATABASE;
    const profile=root.querySelector("#bl-profile");
    const status=root.querySelector("#bl-status");

    function showError(message){
      if(profile){
        profile.innerHTML=`<div class="bl-error" role="alert"><strong>Brand Laboratory could not load.</strong><p>${escapeHtml(message)}</p></div>`;
      }
      if(status) status.textContent="Please refresh the page or verify the Brand Laboratory data files.";
      console.error("GAL Brand Laboratory:",message);
    }

    function escapeHtml(value){
      return String(value??"").replace(/[&<>"']/g,char=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[char]));
    }

    if(!DB||!Array.isArray(DB.brands)||!DB.brands.length){
      showError("The brand database is missing or invalid.");
      return;
    }

    const brands=DB.brands;
    const brandSelect=root.querySelector("#bl-brand-select");
    const typeSelect=root.querySelector("#bl-type-select");
    const searchInput=root.querySelector("#bl-search");
    const sections=root.querySelector("#bl-sections");
    const brandCount=root.querySelector("#bl-brand-count");
    const expandButton=root.querySelector("#bl-expand");
    const collapseButton=root.querySelector("#bl-collapse");
    const checks=[...root.querySelectorAll(".bl-interest-fields input[type='checkbox']")];

    const required={brandSelect,typeSelect,searchInput,sections,profile,status,brandCount,expandButton,collapseButton};
    const missing=Object.entries(required).filter(([,value])=>!value).map(([key])=>key);
    if(missing.length){
      showError(`Required interface controls are missing: ${missing.join(", ")}.`);
      return;
    }

    const labels={science:"Science",economics:"Economics",governance:"Governance",inside:"Inside the Business",products:"Product Family",sources:"Sources"};
    const icons={science:"⚗",economics:"$",governance:"§",inside:"⌂",products:"●",sources:"↗"};

    brandCount.textContent=String(brands.length);

    [...new Set(brands.map(item=>item.category).filter(Boolean))]
      .sort((a,b)=>a.localeCompare(b))
      .forEach(category=>typeSelect.add(new Option(category,category)));

    function fillBrands(){
      const selectedType=typeSelect.value;
      const previous=brandSelect.value;
      brandSelect.innerHTML="";
      brands
        .filter(item=>!selectedType||item.category===selectedType)
        .sort((a,b)=>a.name.localeCompare(b.name))
        .forEach(item=>brandSelect.add(new Option(item.name,item.id)));
      if([...brandSelect.options].some(option=>option.value===previous)) brandSelect.value=previous;
      if(!brandSelect.value&&brandSelect.options.length) brandSelect.selectedIndex=0;
    }

    fillBrands();
    if([...brandSelect.options].some(option=>option.value==="titleist")) brandSelect.value="titleist";

    function currentBrand(){
      return brands.find(item=>item.id===brandSelect.value)||brands[0];
    }

    function highlight(value){
      const escaped=escapeHtml(value);
      const query=searchInput.value.trim();
      if(!query) return escaped;
      const safeQuery=query.replace(/[.*+?^${}()|[\]\\]/g,"\\$&");
      return escaped.replace(new RegExp(`(${safeQuery})`,"ig"),"<mark>$1</mark>");
    }

    function renderProfile(brand){
      profile.innerHTML=`<div class="profiletop"><div><h2>${escapeHtml(brand.name)}</h2><div class="tagline">${escapeHtml(brand.tagline)}</div><p class="summary">${escapeHtml(brand.summary)}</p></div><div class="badges"><span class="badge">${escapeHtml(brand.category)}</span><span class="badge conf">Research: ${escapeHtml(brand.confidence)}</span></div></div><div class="facts">${Object.entries(brand.snapshot||{}).map(([key,value])=>`<div class="fact"><small>${escapeHtml(key)}</small><b>${escapeHtml(value)}</b></div>`).join("")}</div>`;
    }

    function objectBody(object={}){
      return Object.entries(object).map(([key,values])=>{
        const list=Array.isArray(values)?values:[values];
        return `<div class="topic ${key.toLowerCase().includes("unavailable")?"gap":""}"><h4>${highlight(key)}</h4><ul>${list.map(value=>`<li>${highlight(value)}</li>`).join("")}</ul></div>`;
      }).join("");
    }

    function productBody(rows=[]){
      return `<div class="topic bl-table-wrap"><table><thead><tr><th>Model</th><th>Construction</th><th>Cover</th><th>Compression</th><th>Position</th></tr></thead><tbody>${rows.map(row=>`<tr>${row.map(cell=>`<td>${highlight(cell)}</td>`).join("")}</tr>`).join("")}</tbody></table></div>`;
    }

    function sourceBody(rows=[]){
      return `<div class="topic">${rows.map(row=>`<div class="source"><a href="${escapeHtml(row[1])}" target="_blank" rel="noopener noreferrer">${highlight(row[0])}</a><em>${escapeHtml(row[2])}</em></div>`).join("")}</div>`;
    }

    function accordion(key,body,isOpen=false){
      return `<article class="accordion ${isOpen?"open":""}" data-k="${key}"><button class="head" type="button" aria-expanded="${isOpen}"><h3>${icons[key]} ${labels[key]}</h3><span class="toggle" aria-hidden="true">${isOpen?"−":"＋"}</span></button><div class="body">${body}</div></article>`;
    }

    function bindAccordions(){
      root.querySelectorAll(".accordion .head").forEach(button=>{
        button.addEventListener("click",()=>{
          const article=button.closest(".accordion");
          const isOpen=article.classList.toggle("open");
          button.setAttribute("aria-expanded",String(isOpen));
          button.querySelector(".toggle").textContent=isOpen?"−":"＋";
        });
      });
    }

    function applyFilters(){
      const enabled=checks.filter(input=>input.checked).map(input=>input.value);
      root.querySelectorAll(".accordion").forEach(article=>article.classList.toggle("hidden",!enabled.includes(article.dataset.k)));
      const date=DB.meta?.researchDate||"not specified";
      status.textContent=`Showing ${enabled.length} of 6 research views. Database research date: ${date}.`;
    }

    function render(){
      const brand=currentBrand();
      if(!brand){ showError("No brand is available for the selected filter."); return; }
      renderProfile(brand);
      sections.innerHTML=
        accordion("science",objectBody(brand.science),true)+
        accordion("economics",objectBody(brand.economics))+
        accordion("governance",objectBody(brand.governance))+
        accordion("inside",objectBody(brand.inside))+
        accordion("products",productBody(brand.products))+
        accordion("sources",sourceBody(brand.sources));
      bindAccordions();
      applyFilters();
    }

    brandSelect.addEventListener("change",()=>{searchInput.value="";render();});
    typeSelect.addEventListener("change",()=>{fillBrands();searchInput.value="";render();});
    searchInput.addEventListener("input",render);
    checks.forEach(input=>input.addEventListener("change",applyFilters));

    expandButton.addEventListener("click",()=>{
      root.querySelectorAll(".accordion:not(.hidden)").forEach(article=>{
        article.classList.add("open");
        const button=article.querySelector(".head");
        button.setAttribute("aria-expanded","true");
        button.querySelector(".toggle").textContent="−";
      });
    });

    collapseButton.addEventListener("click",()=>{
      root.querySelectorAll(".accordion:not(.hidden)").forEach(article=>{
        article.classList.remove("open");
        const button=article.querySelector(".head");
        button.setAttribute("aria-expanded","false");
        button.querySelector(".toggle").textContent="＋";
      });
    });

    render();
    root.dataset.initialized="true";
  }

  if(document.readyState==="loading") document.addEventListener("DOMContentLoaded",initBrandLaboratory,{once:true});
  else initBrandLaboratory();
})();
