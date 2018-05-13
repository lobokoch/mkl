package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Slot

class JavaEntityDTOConverterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	private static val ENTITY = 'entity'
	private static val DTO = 'dto'
	
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
		val manyToOneSlots = entity.slots.filter[it.isManyToOne]
		val imports = manyToOneSlots.generateImports
		
		'''
		package «entity.package»;
		
		import org.modelmapper.ModelMapper;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.stereotype.Component;
		
		«imports.map[it].join('\r\n')»
		
		@Component
		public class «entity.toDTOConverterName» {
			
			@Autowired
			ModelMapper modelMapper;
			
			public «entity.toEntityDTOName» convert(«entity.toEntityName» «ENTITY») {
				«entity.toEntityDTOName» «DTO» = modelMapper.map(«ENTITY», «entity.toEntityDTOName».class);
				«manyToOneSlots.map[generateDTOAssign].join('\n\r')»
				return «DTO»;
			}
			
			public «entity.toEntityName» convert(«entity.toEntityDTOName» «DTO») {
				«entity.toEntityName» «ENTITY» = modelMapper.map(«DTO», «entity.toEntityName».class);
				«manyToOneSlots.map[generateEntityAssign].join('\n\r')»
				
				return «ENTITY»;
			}
		
		}
		'''
	}
	
	def generateImports(Iterable<Slot> slots) {
		val imports = newArrayList
		val entities = slots.map[it.asEntity]
		entities.forEach[entity |
			imports.add(entity.entityImport)
			//imports.add(entity.entityDTOImport)
		]
		
		imports
	}
	
	def CharSequence generateEntityAssign(Slot slot) {
		'''
		if («ENTITY».«slot.buildMethodGet» == null) {
			«slot.asEntity.toEntityName» «slot.name» = new «slot.asEntity.toEntityName»();
			«slot.name».«slot.asEntity.id.buildMethodSet(DTO + '.' + slot.buildMethodGet)»;
			«ENTITY».«slot.buildMethodSet(slot.name)»;
		}
		'''
	}
	
	def CharSequence generateDTOAssign(Slot slot) {
		'''
		«DTO».«slot.buildMethodSet(ENTITY + '.' + slot.buildMethodGet + '.' + slot.asEntity.id.buildMethodGet)»;
		'''
	}
	
}