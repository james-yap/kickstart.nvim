local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets('markdown', {
	s({trig = 'mi', name = 'Math (inline)'}, {
		t '\\(',
		i(1),
		t '\\) ',
		i(0)
	})
})

ls.add_snippets('markdown', {
	s({trig = 'mb', name = 'Math (block)'}, {
		t { '', '', '\\[', '' },
		i(1),
		t { '', '\\]', '', '' },
		i(0)
	})
})

ls.add_snippets('markdown', {
	s({trig = '\\op', name = 'Operator name'}, {
		t '\\operatorname{',
		i(1),
		t '}',
		i(0)
	})
})

ls.filetype_extend('tex', {'markdown'})
