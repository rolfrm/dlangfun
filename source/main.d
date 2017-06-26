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

void render_voxels(void delegate () render){
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

void print_octree_positions(T)(OctreeIndex!T oct, void delegate(float s, float x, float y, float z, ref T payload) fcn, float s = 1.0f, float x = 0.0f, float y = 0.0f, float z= 0.0f){
  
  void recurse(OctreeIndex!T index, float size, float x, float y, float z){
    fcn(size, x, y, z, index.get_payload());
    if(index.get_type() == NodeType.Cell){
      int[8] order = [5, 4, 1, 0, 7, 6, 3, 2];
      for(int _i = 0; _i < 8; _i++){
	int i = order[_i];
	float dx = i % 2;
	float dy = (i / 2) % 2;
	float dz = (i / 4) % 2;
	float halfsize = size * 0.5;
	recurse(index.get_child(i), halfsize, x + dx * halfsize, y + dy * halfsize, z + dz * halfsize);
      }
    }
  }
  recurse(oct, s, x, y, z);
}
void printPos(float size, float x, float y, float z, ref int payload){
  writefln("%s %s %s %s %s", x, y, z, size, payload);
  }

class entity{
  Octree!int model;
  float[3] offset;
}

class OctreeRenderer{
  uint buffer;
  int vertexes;
  uint prog;
  bool loaded;
  entity[] entities;
  
  float t;
}

void load(OctreeRenderer renderer){
  auto fs = compileShader(GL_FRAGMENT_SHADER, readText("simple_shader.fs"));
  auto vs = compileShader(GL_VERTEX_SHADER, readText("simple_shader.vs"));
  auto prog = glCreateProgram();
  prog.glAttachShader(fs);
  glAttachShader(prog, vs);
  glLinkProgram(prog);
  glUseProgram(prog);
  
  //double[] data = [0,0, 0,1, 1,-1, 1,2, 2,0, 2, 1];
  double[] data = [0,0, -1,1, 1,1, -1,2, 1,2, 0, 3];
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
      if(payload < renderer.entities.length){
	
	auto entity = renderer.entities[payload];
	print_octree_positions!int(entity.model.first_index, &print_voxel, size, x + entity.offset[0], y + entity.offset[1], z + entity.offset[2]);
	
      }else{
	int r = payload % 4;
	int g = (payload / 4) % 4;
	glUniform4f(glGetUniformLocation(renderer.prog, "color"), r / 4.0f, g / 4.0f, 0.5, 1);
	glUniform3f(glGetUniformLocation(renderer.prog, "position"), x, y, z);
	glUniform1f(glGetUniformLocation(renderer.prog, "size"), size);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, renderer.vertexes);

      }
      //writefln("%s %s %s %s %s", size, x, y, z, payload);
    }
  }
  print_octree_positions(oct, &print_voxel);
  void printPos(float size, float x, float y, float z, ref int payload){
    writefln("%s %s %s %s %s",  x, y, z, size,payload);
  }
}




void main(string[] args){

  string[] fruits = ["banana", "mango", "apple", "asd"];
  writeln("hello world!");
  writeln((fruits ~ "banana2")[4]);
  string * fp = &(fruits[0]);
  writeln(fp[1]);
  printThing(fp[0]);
  printThing(1);
  
  auto simple_model = new Octree!int();
  auto s1 = simple_model.first_index;
  s1.get_child(0,0,0).get_child(1,1,1).get_payload = 256;
  s1.get_child(1,0,0).get_child(0,1,1).get_payload = 256;
  s1.get_child(0,1,0).get_child(1,0,1).get_payload = 270;
  s1.get_child(0,0,1).get_child(1,1,0).get_payload = 276;
  s1.get_child(1,1,0).get_child(0,0,1).get_payload = 256;
  s1.get_child(1,0,1).get_child(0,1,0).get_payload = 256;
  s1.get_child(0,1,1).get_child(1,0,0).get_payload = 270;
  s1.get_child(1,1,1).get_child(0,0,0).get_payload = 276;
  
  entity e1 = new entity();
  e1.offset[0] = 0.0;
  e1.offset[1] = 0.0;
  e1.offset[2] = 0.0;
  e1.model = simple_model;

  entity e2 = new entity();
  e2.offset[0] = 0.0;
  e2.offset[1] = 0.0;
  e2.offset[2] = 0.0;
  e2.model = simple_model;

  
  
  auto oct = new Octree!int();
  
  auto idx2 = oct.first_index;
  bool[15] x;
  writeln(x.sizeof);
  writeln(int.sizeof);
  /*
  for(int j = 0; j < 8; j++)
    for(int i = 0; i < 8; i++){
      if(j < 7 && i < 7 && j != 2){
	idx2.get_child(j).get_child(i).get_payload = i + 255;
      }
    }
  int test = 0;
  for(int j = 0; j < 8; j++)
    for(int i = 0; i < 8; i++){
      if(j >= 7 || i >= 7){
	
	auto sub = idx2.get_child(j).get_child(i);
	  for(int i2 = 0; i2 < 8; i2++){
	    for(int j2 = 0; j2 < 8; j2++){
	      if(j2 != 2){
		if(test % 5 == 0){
		  sub.get_child(j2).get_child(i2).get_payload() = i2 + 255;
		}else{
		  sub.get_child(j2).get_payload = 0;
		}
	      }
	      
	      test++;
	    }
	  }
      }
      }*/
  OctreeRenderer renderer = new OctreeRenderer();
  renderer.entities.length = 3;
  renderer.entities[1] = e1;
  renderer.entities[2] = e2;
  idx2.get_child(0).get_payload = 40;
  idx2.get_child(1).get_payload = 50;
  idx2.get_child(2).get_payload = 1;
  idx2.get_child(3).get_payload = 2;
  idx2.get_child(4).get_payload = 15;
  idx2.get_child(5).get_payload = 20;
  idx2.get_child(6).get_payload = 25;
  idx2.get_child(7).get_payload = 30;
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
  float t = 0.0;
  render_voxels( {
      render(renderer, idx2);
      renderer.entities[1].offset[1] = sin(t) * 0.1;
      renderer.entities[2].offset[0] = sin(t) * 0.1;
      renderer.entities[2].offset[2] = cos(t) * 0.1;
      
      t += 0.001;
    });
}
