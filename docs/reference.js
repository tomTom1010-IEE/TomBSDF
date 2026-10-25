const search = document.querySelector('#parameter-search');
const select = document.querySelector('#shader-filter');
const output = document.querySelector('#result-count');
const sections = [...document.querySelectorAll('[data-parameter-shader]')];
function filter() {
  const query = search.value.trim().toLowerCase();
  let count = 0;
  for (const section of sections) {
    let visible = 0;
    const selected = !select.value || section.dataset.parameterShader === select.value;
    for (const row of section.querySelectorAll('[data-parameter]')) {
      row.hidden = !selected || (query !== '' && !row.textContent.toLowerCase().includes(query));
      if (!row.hidden) visible++;
    }
    for (const group of section.querySelectorAll('[data-parameter-group]')) {
      group.hidden = ![...group.querySelectorAll('[data-parameter]')].some(row => !row.hidden);
    }
    section.hidden = visible === 0;
    count += visible;
  }
  output.textContent = `${count} matching parameter${count === 1 ? '' : 's'}`;
}
search.addEventListener('input', filter);
select.addEventListener('change', filter);
filter();
