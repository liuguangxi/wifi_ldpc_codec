% performs ldpc encoding.
function bits = ldpc_encode(inp,blk_size,code_rate_enum)

generator_matrix = calculate_generator_matrix(blk_size,code_rate_enum);
parity = bitand((generator_matrix * inp) , 1);
bits = [inp; parity];

end
