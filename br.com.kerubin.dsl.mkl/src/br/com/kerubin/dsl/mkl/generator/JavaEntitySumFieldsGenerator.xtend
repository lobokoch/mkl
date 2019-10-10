package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntitySumFieldsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[it.hasSumFields].forEach[generateContaPagarSumFields]
	}
	
	def generateContaPagarSumFields(Entity entity) {
		val slots = entity.getSumFieldSlots
		if (!slots.isEmpty) {
			val basePakage = clientGenSourceFolder
			val entityFile = basePakage + entity.packagePath + '/' + entity.toEntitySumFieldsName + '.java'
			generateFile(entityFile, entity.doGenerateContaPagarSumFields(slots))
		}
	}
	
	def CharSequence doGenerateContaPagarSumFields(Entity entity, Iterable<Slot> slots) {	
		entity.imports.clear
		
		val isEnableDoc = entity.service.isEnableDoc
		if (isEnableDoc) {
			entity.addImport('import io.swagger.annotations.ApiModel;')
			
			if (!slots.empty) {
				entity.addImport('import io.swagger.annotations.ApiModelProperty;')
			}
		}
		val title = entity.title
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		«IF isEnableDoc»
				
		@ApiModel(description = "Details about sums of «title»")
		«ENDIF»
		public class «entity.toEntitySumFieldsName» {
			
			«entity.generateFields(slots)»
			«entity.toEntitySumFieldsName.generateNoArgsConstructor»
			«entity.generateGetters(slots)»
			«entity.generateSetters(slots)»
		
		}
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		
		package + imports + body 
	}
	
	def CharSequence generateFields(Entity entity, Iterable<Slot> slots) {
		'''
		«slots.map[generateField(entity)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		val isEnableDoc = entity.service.isEnableDoc
		val title = slot.title
		
		'''
		«IF isEnableDoc»
		@ApiModelProperty(notes = "Sum of «title»")
		«ENDIF»
		private «slot.toJavaType» «slot.sumFieldName»;
		'''
	}
	
	def CharSequence generateGetters(Entity entity, Iterable<Slot> slots) {
		'''
		
		«slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		'''«slot.getGetMethod('sum', '')»'''
	}
	
	def CharSequence generateSetters(Entity entity, Iterable<Slot> slots) {
		'''
		
		«slots.map[generateSetter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		'''«slot.getSetMethod('sum', '')»'''
	}
	
}