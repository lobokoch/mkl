package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaEntityDTOConverterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateEntityDTOConverter]
	}
	
	def generateEntityDTOConverter(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toDTOConverterName + '.java'
		generateFile(fileName, entity.generateDTOConverter)
	}
	
	def CharSequence generateDTOConverter(Entity entity) {
		'''
		package «entity.package»;
		
		import org.modelmapper.ModelMapper;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.stereotype.Component;
		
		@Component
		public class «entity.toDTOConverterName» {
			
			@Autowired
			ModelMapper modelMapper;
			
			public «entity.toEntityDTOName» convert(«entity.toEntityName» source) {
				«entity.toEntityDTOName» destination = modelMapper.map(source, «entity.toEntityDTOName».class);
				return destination;
			}
			
			public «entity.toEntityName» convert(«entity.toEntityDTOName» source) {
				«entity.toEntityName» destination = modelMapper.map(source, «entity.toEntityName».class);
				return destination;
			}
		
		}
		'''
	}
	
}