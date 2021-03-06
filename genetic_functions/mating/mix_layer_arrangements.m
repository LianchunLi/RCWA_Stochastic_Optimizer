
% function which mixes layers...which is to say: split structure 1 and 2 in
% half, then mix top and bottom of 1 and 2 and bottom and top of 1 and 2.

function [child1, child2] = mix_layer_arrangements(structure1, structure2)
    
    %% layer structures, thicknesses, and dielectric tensors of structure 1
    ls1 = structure1.layer_structures;
    lt1 = structure1.layer_thicknesses;
    ldt1 = structure1.layer_dielectric_tensors; %specifies dielectric tensor for each layer
  
    %% layer structures, thicknesses, and dielectric tensors of structure 2
    ls2 = structure2.layer_structures;
    lt2 = structure2.layer_thicknesses;
    ldt2 = structure2.layer_dielectric_tensors;
    
    l1 = length(ls1); l2 = length(ls2);
    split1 = randi([1, l1],1);
    split2 = randi([1, l2],1);
    
    [ls3, ls4] = partition_cell(ls1, ls2, split1, split2); %partition structure
    [lt3, lt4] = partition_array(lt1, lt2, split1, split2); %parition thicknesses
    [ldt3, ldt4] = partition_cell(ldt1, ldt2, split1, split2); %partition dielectric specs
    
    lattice_constant = structure1.lattice_constant;
    num_layers1 = length(ls3);
    num_layers2 = length(ls4);
    child1 = layered_structure_class(num_layers1, lattice_constant, ...
              ldt3, ls3, lt3);
    child2 = layered_structure_class(num_layers2, lattice_constant, ...
              ldt4, ls4, lt4);
    
end