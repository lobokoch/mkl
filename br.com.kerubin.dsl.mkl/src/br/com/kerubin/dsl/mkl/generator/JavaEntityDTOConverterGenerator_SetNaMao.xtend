package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Slot
import java.util.List

class JavaEntityDTOConverterGenerator_SetNaMao extends GeneratorExecutor implements IGeneratorExecutor {
	
	private static val ENTITY = 'entity'
	private static val ENTITY_LIST = 'entityList'
	private static val DTO = 'dto'
	
	private static val CONVERT_TO_DTO = 'convertToDto'
	private static val CONVERT_TO_DTO_LIST = 'convertToDtoList'
	//private static val CONVERT_TO_DTO_LR = 'convertToDtoLookupResult'
	//private static val CONVERT_TO_DTO_LR_LIST = 'convertToDtoLookupResultList'
	
	private static val CONVERT_TO_ENTITY = 'convertToEntity'
	
	val List<String> imports = newArrayList
	
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
		
		val entitySlots = entity.slots.filter[it.isEntity && it.isRelationContains]
		entitySlots.generateImports(imports)
		//entitySlots.forEach[it | imports.add(it.asEntity.entityDTOImport)]
		
		
		'''
		package «entity.package»;
		
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.stereotype.Component;
		import java.util.List;
		import java.util.Collection;
		import java.util.stream.Collectors;
		
		«imports.map[it].join('\r\n')»
		
		@Component
		public class «entity.toDTOConverterName» {
			
			«entitySlots.map[it.generateAutowiredDTOConverter].join»
			
			public «entity.toEntityDTOName» «br.com.kerubin.dsl.mkl.generator.JavaEntityDTOConverterGenerator_SetNaMao.CONVERT_TO_DTO»(«entity.toEntityName» «ENTITY») {
				«entity.toEntityDTOName» «DTO» = null;
				if («ENTITY» != null) {
					«DTO» = new «entity.toEntityDTOName»();
					«entity.slots.map[it.generateDtoAssign].join»
				}
				return «DTO»;
			}
			
			public List<«entity.toEntityDTOName»> «br.com.kerubin.dsl.mkl.generator.JavaEntityDTOConverterGenerator_SetNaMao.CONVERT_TO_DTO_LIST»(Collection<«entity.toEntityName»> «ENTITY_LIST») {
				List<«entity.toEntityDTOName»> «DTO» = null;
				if («ENTITY_LIST» != null) {
					«DTO» = «ENTITY_LIST».stream().map(this::«br.com.kerubin.dsl.mkl.generator.JavaEntityDTOConverterGenerator_SetNaMao.CONVERT_TO_DTO»).collect(Collectors.toList());
				}
				return «DTO»;
			}
			
			public «entity.toEntityName» «br.com.kerubin.dsl.mkl.generator.JavaEntityDTOConverterGenerator_SetNaMao.CONVERT_TO_ENTITY»(«entity.toEntityDTOName» «DTO») {
				«entity.toEntityName» «ENTITY» = null;
				
				
				return «ENTITY»;
			}
		
		}
		'''
	}
	
	def CharSequence generateConvertEntityToDto(Entity entity) {
		'''
		public «entity.toEntityDTOName» «CONVERT_TO_DTO»(«entity.toEntityName» «ENTITY») {
			«entity.toEntityDTOName» «DTO» = null;
			if («ENTITY» != null) {
				«DTO» = new «entity.toEntityDTOName»();
				«entity.slots.map[it.generateDtoAssign].join»
			}
			return «DTO»;
		}
		'''
	}
	
	def CharSequence generateDtoAssign(Slot slot) {
		slot.generateAssign(ENTITY, DTO)
		
		/*'''
		«IF slot.isEntity»
		«slot.generateEntityAssign»
		«ELSE»
		«DTO.buildMethodSet(slot, ENTITY.buildMethodGet(slot))»;
		«ENDIF»
		'''*/
	}
	
	def CharSequence generateAssign(Slot slot, String source, String destination) {
		'''
		«IF slot.isEntity»
		«slot.generateEntityAssign(source, destination)»
		«ELSE»
		«destination.buildMethodSet(slot, source.buildMethodGet(slot))»;
		«ENDIF»
		'''
	}
	
	def CharSequence generateEntityAssign(Slot slot, String source, String destination) {
		'''
		
		if («ENTITY.buildMethodGet(slot)» != null) {
			«IF slot.isRelationRefers && !slot.isMany»
			«DTO.buildMethodSet(slot, ENTITY.buildMethodGetEntityId(slot))»;
			«ELSEIF slot.isRelationContains»
			«IF slot.isMany»
			«DTO.buildMethodSet(slot, slot.buildMethodConvertToListDTO)»;
			«ELSE»
			«DTO.buildMethodSet(slot, slot.buildMethodConvertToDTO)»;
			«ENDIF»
			«ENDIF»
		}
		'''
	}
	
	def CharSequence generateConvertToDtoLookupResult() {
		
	}
	
	def CharSequence generateConvertToDtoList() {
		
	}
	
	def CharSequence generateConvertToDtoLookupResultList() {
		
	}
	
	////
	
	def CharSequence generateConvertToEntity() {
		
	}
	
	def CharSequence generateConvertToEntityList() {
		
	}
	
	def CharSequence generateAutowiredDTOConverter(Slot slot) {
		val entity = slot.asEntity
		
		'''
		
		@Autowired
		private «entity.toDTOConverterName» «entity.toDTOConverterVar»;
		'''
	}
	
	
	
	
	
	def generateImports(Iterable<Slot> slots, List<String> imports) {
		val entities = slots.map[it.asEntity]
		entities.forEach[entity | 
			imports.add(entity.entityImport)
			imports.add(entity.getEntityDTOConverterImport)			
		]
	}
	
	def CharSequence generateEntityAssign_OLD(Slot slot) {
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