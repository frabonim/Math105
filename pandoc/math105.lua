local utils = require("pandoc.utils")

local function stringify(el)
  return utils.stringify(el)
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function has_class(el, class_name)
  for _, class in ipairs(el.classes) do
    if class == class_name then
      return true
    end
  end
  return false
end

local function add_class(el, class_name)
  if not has_class(el, class_name) then
    table.insert(el.classes, class_name)
  end
end

local function remove_class(el, class_name)
  local classes = {}
  for _, class in ipairs(el.classes) do
    if class ~= class_name then
      table.insert(classes, class)
    end
  end
  el.classes = classes
end

local function style_of(el)
  return el.attributes and el.attributes.style or ""
end

local function clear_style(el)
  if el.attributes then
    el.attributes.style = nil
  end
end

local function has_attributes(el)
  if not el.attributes then
    return false
  end

  for _, _ in pairs(el.attributes) do
    return true
  end

  return false
end

function Span(el)
  local style = style_of(el)
  local text = trim(stringify(el))

  if style == "color: defhead" then
    clear_style(el)
    add_class(el, "defined-term")
    return el
  end

  if style == "color: exhead" and text == "Example" then
    clear_style(el)
    add_class(el, "box-label")
    add_class(el, "example-label")
    return el
  end

  if style == "background-color: defhead" and text == "Definition" then
    clear_style(el)
    add_class(el, "box-label")
    add_class(el, "definition-label")
    return el
  end

  if style == "background-color: notehead" and text == "NOTE" then
    clear_style(el)
    add_class(el, "box-label")
    add_class(el, "note-label")
    return el
  end

  return nil
end

function Div(el)
  local style = style_of(el)

  if style == "background-color: defbod" then
    clear_style(el)
    add_class(el, "definition-box")
    return el
  end

  if style == "background-color: notebod" then
    clear_style(el)
    add_class(el, "note-box")
    return el
  end

  if has_class(el, "minipage") then
    remove_class(el, "minipage")
    if el.identifier == "" and #el.classes == 0 and not has_attributes(el) then
      return el.content
    end
    return el
  end

  if has_class(el, "allrules") then
    remove_class(el, "allrules")
    add_class(el, "fact-box")
    return el
  end

  if has_class(el, "siderules") then
    remove_class(el, "siderules")
    add_class(el, "example-box")
    return el
  end

  return nil
end

function Para(el)
  if #el.content ~= 1 or el.content[1].t ~= "Span" then
    return nil
  end

  local span = el.content[1]
  if #span.classes > 0 or has_attributes(span) then
    return nil
  end

  if #span.content ~= 1 or span.content[1].t ~= "Strong" then
    return nil
  end

  local heading_text = trim(stringify(span.content[1]))
  if heading_text == "" then
    return nil
  end

  return pandoc.Header(3, span.content[1].content, pandoc.Attr("", { "lesson-subhead" }, {}))
end
