import std.container;
import std.stdio;
enum NodeType { Payload, Cell}

class Octree(T){
  union payloadOrIndex{
    T payload;
    int index;
  }
	
  NodeType[8][] type;
  payloadOrIndex[8][] sub_nodes;
  T[] payload;
  int count;
	
  this(){
    type.length = 1;
    sub_nodes.length = 1;
    payload.length = 1;
    count = 1;
  }
}

void expand(T)(Octree!T oct, int elements){
  oct.type.length += elements;
  oct.sub_nodes.length += elements;
  oct.payload.length += elements;
}

struct OctreeIndex(T){
  Octree!T basetree;
  const int parent_index;
  const int child_index;
	
  this(Octree!T basetree, int parent_index, int child_index){
    this.parent_index = parent_index;
    this.child_index = child_index;
    this.basetree = basetree;
  }
}

OctreeIndex!T first_index(T)(Octree!T oct){
  return OctreeIndex!T(oct, 0, -1);
}

int next_index(T)(Octree!T oct){
  if(oct.count == oct.type.length)
    oct.expand(oct.count);
  return oct.count++;
}

bool has_child(T)(OctreeIndex!T index, int n){
  assert(index.child_index == -1);
}

OctreeIndex!T expand(T)(OctreeIndex!T index){
  if(index.child_index == -1){
    return index;
  }
  else{
    if(index.basetree.type[index.parent_index][index.child_index] == NodeType.Payload){
      index.basetree.type[index.parent_index][index.child_index] = NodeType.Cell;
      int newidx = index.basetree.next_index();
      index.basetree.sub_nodes[index.parent_index][index.child_index].index = newidx;
      return OctreeIndex!T(index.basetree, newidx, -1);
    }else{
      int idx = index.basetree.sub_nodes[index.parent_index][index.child_index].index;
      return OctreeIndex!T(index.basetree, idx, -1);      
    }
  }
}

OctreeIndex!T get_child(T)(OctreeIndex!T index, int child_index, bool create = true){
  assert(child_index >= 0);
  assert(child_index < 8);
  if(index.child_index != -1)
    return get_child(index.expand(), child_index, create);
  
  return OctreeIndex!T(index.basetree, index.parent_index, child_index); 
}

OctreeIndex!T get_child(T)(OctreeIndex!T index, int x, int y, int z, bool create = true){
  return get_child(index, x + y * 2 + z * 4, create);
}

NodeType get_type(T)(OctreeIndex!T index){
  if(index.child_index == -1) return NodeType.Cell;
  return index.basetree.type[index.parent_index][index.child_index];
}

ref T get_payload(T)(OctreeIndex!T index){
  Octree!T oct = index.basetree;
  if(index.child_index == -1)
    return oct.payload[index.parent_index];
  if(oct.type[index.parent_index][index.child_index] == NodeType.Cell)
    {
      int idx = oct.sub_nodes[index.parent_index][index.child_index].index;
      return oct.payload[idx];
    }
  return oct.sub_nodes[index.parent_index][index.child_index].payload;
     
}
