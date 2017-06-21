import std.stdio;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.string;
import std.file;
import std.math;
import octree;
int function(int x) myf;

void printThing(T)(T x){
  writeln(x);
}

uint compileShader(GLenum program, string code){
  uint ss = glCreateShader(program);
  int length = cast(int)code.length;
  immutable(char)*  codestr = toStringz(code);
  glShaderSource(ss, 1, &codestr, &length); 
  glCompileShader(ss);
  int compileStatus = 0;	
  glGetShaderiv(ss, GL_COMPILE_STATUS, &compileStatus);
  if(compileStatus == 0){
    writeln("Error during shader compilation:");
    int loglen;
    glGetShaderiv(ss, GL_INFO_LOG_LENGTH, &loglen);
    char[] buffer = new char[loglen];
    char * bufptr = &buffer[0];
    glGetShaderInfoLog(ss, loglen, null, bufptr);
    writeln(buffer);
  } else{
    writeln("Compiled shader with success");
  }
  return ss;
}

void render_voxels(void delegate() render){
  DerelictGLFW3.load();
  DerelictGL3.load();
  glfwInit();  
  auto win = glfwCreateWindow(512, 512, "hello", null, null);
  
  glfwMakeContextCurrent(win);
  DerelictGL3.reload();
  
  //DerelictGL3.bindFunc(ptr, funcName, doThrow);
  glClearColor(0.8, 0.8, 0.8, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
  glfwSwapBuffers(win);
  
  while(false == glfwWindowShouldClose(win)){
    int width, height;
    glfwGetWindowSize(win,&width, &height);
    if(width > 0 && height > 0)
      glViewport(0, 0, width, height); 
    glClear(GL_COLOR_BUFFER_BIT);
    render();
    glfwSwapBuffers(win);  
    glfwPollEvents();
  }
  glfwDestroyWindow(win);
	
}

void print_octree_positions(T)(OctreeIndex!T oct, void delegate(float s, float x, float y, float z, ref T payload) fcn){
  
  void recurse(OctreeIndex!T index, float size, float x, float y, float z){
    fcn(size, x, y, z, index.get_payload());
    if(index.get_type() == NodeType.Cell){
      int[8] order = [5, 4, 1, 0, 7, 6, 3, 2];
      for(int _i = 0; _i < 8; _i++){
	int i = order[_i];
	float dx = i % 2;
	float dy = (i / 2) % 2;
	float dz = (i / 4) % 2;
	recurse(index.get_child(i), size * 0.5, x + dx * size * 0.5, y + dy * size * 0.5, z + dz * size * 0.5);
      }
    }
  }
  recurse(oct, 1, 0, 0, 0);
}
void printPos(float size, float x, float y, float z, ref int payload){
    writefln("%s %s %s %s %s", size, x, y, z, payload);
  }

class OctreeRenderer{
  uint buffer;
  int vertexes;
  uint prog;
  bool loaded;
  float t;
}

void load(OctreeRenderer renderer){
  auto fs = compileShader(GL_FRAGMENT_SHADER, readText("simple_shader.fs"));
  auto vs = compileShader(GL_VERTEX_SHADER, readText("simple_shader.vs"));
  auto prog = glCreateProgram();
  glAttachShader(prog, fs);
  glAttachShader(prog, vs);
  glLinkProgram(prog);
  glUseProgram(prog);
  
  double[] data = [0,0, 0,1, 1,-1, 1,2, 2,0, 2, 1];
  uint buffer;
  glGenBuffers(1, &buffer);
  glBindBuffer(GL_ARRAY_BUFFER, buffer);
  glBufferData(GL_ARRAY_BUFFER, data.length * 8, cast(void *) data, GL_DYNAMIC_DRAW);
  renderer.buffer = buffer;
  renderer.prog = prog;
  renderer.loaded = true;
  renderer.vertexes = cast(int) data.length / 2;
}

void render(OctreeRenderer renderer, OctreeIndex!int oct ){
  if(!renderer.loaded)
    renderer.load();
  
  glUseProgram(renderer.prog);
  glBindBuffer(GL_ARRAY_BUFFER, renderer.buffer);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_DOUBLE, false, 0, null);
  //writeln(renderer.t);
  void print_voxel(float size, float x, float y, float z, ref int payload){
    if(payload != 0){
      //writefln("%s %s %s %s %s", size, x, y, z, payload);
      
      int r = payload % 4;
      int g = (payload / 4) % 4;
      glUniform4f(glGetUniformLocation(renderer.prog, "color"), r / 4.0f, g / 4.0f, 0.5, 1);
      glUniform3f(glGetUniformLocation(renderer.prog, "position"), x, y, z);
      glUniform1f(glGetUniformLocation(renderer.prog, "size"), size);
      glDrawArrays(GL_TRIANGLE_STRIP, 0, renderer.vertexes);
    
    }
  }
  print_octree_positions(oct, &print_voxel);
  void printPos(float size, float x, float y, float z, ref int payload){
    writefln("%s %s %s %s %s", size, x, y, z, payload);
  }

   print_octree_positions(oct, &printPos);

}




void main(string[] args){

  string[] fruits = ["banana", "mango", "apple", "asd"];
  writeln("hello world!");
  writeln((fruits ~ "banana2")[4]);
  string * fp = &(fruits[0]);
  writeln(fp[1]);
  printThing(fp[0]);
  printThing(1);
  
  auto oct = new Octree!int();
  auto idx2 = oct.first_index();
  bool[15] x;
  writeln(x.sizeof);
  writeln(int.sizeof);
  auto idx3 = idx2.get_child(3, true);
  writeln(idx3);
  auto idx5 = idx3.get_child(2).get_child(1);
  writeln(idx5);
  writeln(idx3.get_child(2).get_child(1));
  writeln(idx3.get_child(5).get_child(3));
  auto idx4 = idx2;//.get_child(3).get_child(2);
  /*idx3.get_child(2).get_child(3).get_payload() = 1;
  idx3.get_child(2).get_child(2).get_payload() = 2;
  idx3.get_child(2).get_child(6).get_payload() = 3;
  idx3.get_child(3).get_child(3).get_payload() = 1;
  idx3.get_child(3).get_child(2).get_payload() = 2;*/
  for(int j = 0; j < 8; j++)
  for(int i = 0; i < 8; i++){
    if(j < 7 && i < 7)
      idx4.get_child(j).get_child(i).get_payload() = i + 1;
  }
  for(int j = 0; j < 8; j++)
    for(int i = 0; i < 8; i++){
      if(j >= 7 || i >= 7){
	auto sub = idx4.get_child(j).get_child(i);
	for(int i2 = 0; i2 < 8; i2++){
	  for(int j2 = 0; j2 < 8; j2++){
	    sub.get_child(j2).get_child(i2).get_payload() = i2 + 1;
	  }
	}
      }
  }
  /*
  idx3.get_child(0).get_payload() = 3;
  idx3.get_child(1).get_payload() = 3;
  idx3.get_child(4).get_payload() = 3;
  idx3.get_child(5).get_payload() = 3;*/
  //idx3.get_child(5).get_payload() = 4;
  //assert(1 == idx3.get_child(5).get_child(3).get_payload());
  //assert(2 == idx3.get_child(5).get_child(2).get_payload());
  //assert(3 == idx3.get_child(5).get_child(6).get_payload());
  //assert(4 == idx3.get_child(5).get_payload());
  //  auto f = &printPos;

  bool first = false;
  OctreeRenderer renderer = new OctreeRenderer();
  render_voxels(() => renderer.render(idx2));
}