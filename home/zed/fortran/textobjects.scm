(function) @function.around
(function . (function_statement) . (_)* @function.inside . (end_function_statement))
(subroutine) @function.around
(subroutine . (subroutine_statement) . (_)* @function.inside . (end_subroutine_statement))
(module) @class.around
(derived_type_definition) @class.around
(comment) @comment.around
