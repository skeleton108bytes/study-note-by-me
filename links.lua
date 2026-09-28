function Link(el)
  if el.classes:includes("wikilink") and not el.target:match("%.html$") then
    el.target = el.target .. ".html"
  end
  el.target = el.target:gsub("%.md$", ".html")
  return el
end