package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import java.util.Set

class JavaEntityAutoCompleteGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateAutoCompleteInterface]
		entities.forEach[generateAutoCompleteImpl]
	}
	
	def generateAutoCompleteInterface(Entity entity) {
		val slots = entity.slots.filter[it.isAutoCompleteResult || it.isAutoCompleteData]
		if (!slots.isEmpty) {
			val basePakage = clientGenSourceFolder // CLIENT
			val entityFile = basePakage + entity.packagePath + '/' + entity.toAutoCompleteName + '.java'
			generateFile(entityFile, entity.generateEntityAutoComplete(slots))
		}
	}
	
	def generateAutoCompleteImpl(Entity entity) {
		val slots = entity.slots.filter[it.isAutoCompleteResult || it.isAutoCompleteData]
		if (!slots.isEmpty) {
			val basePakage = serverGenSourceFolder // SERVER
			val entityFile = basePakage + entity.packagePath + '/' + entity.toAutoCompleteImplName + '.java'
			generateFile(entityFile, entity.generateEntityAutoCompleteImpl(slots))
		}
	}
	
	def CharSequence generateEntityAutoComplete(Entity entity, Iterable<Slot> slots) {
		
		val imports = newLinkedHashSet
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		public interface «entity.toAutoCompleteName» {
		
			«slots.generateGetters(imports)»
			
			«slots.generateSetters(imports)»
		
		}
		'''
		package + imports.join('\r\n') + '\r\n' + body 
	}
	
	def CharSequence generateGetters(Iterable<Slot> slots, Set<String> imports) {
		'''
		«slots.map[generateGetter(imports)].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetters(Iterable<Slot> slots, Set<String> imports) {
		'''
		«slots.map[generateSetter(imports)].join('\r\n')»
		'''
	}
	
	def CharSequence generateGetter(Slot slot, Set<String> imports) {
		'''
		«slot.resolveSlotAutocomplete(imports)» get«slot.name.toFirstUpper»();
		'''
	}
	
	def CharSequence generateSetter(Slot slot, Set<String> imports) {
		'''
		void set«slot.name.toFirstUpper»(«slot.resolveSlotAutocomplete(imports)» «slot.fieldName»);
		'''
	}
	
	///// IMPL ***************
	def CharSequence generateEntityAutoCompleteImpl(Entity entity, Iterable<Slot> slots) {
		
		val imports = newLinkedHashSet
		
		imports.add('import lombok.Getter;')
		imports.add('import lombok.Setter;')
		
		val classNameImpl = entity.toAutoCompleteImplName
		
		val isEnableDoc = entity.service.isEnableDoc
		if (isEnableDoc) {
			imports.add('import io.swagger.annotations.ApiModel;')
			imports.add('import io.swagger.annotations.ApiModelProperty;')
		}
		val title = entity.title
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		«IF isEnableDoc»
		@ApiModel(description = "Details about «title»")
		«ENDIF»
		@Getter @Setter
		public class «classNameImpl» implements «entity.toAutoCompleteName» {
		
			«slots.generateSlotsImpl(imports)»
			«classNameImpl.generateNoArgsConstructor»
		
		}
		'''
		package + imports.join('\r\n') + '\r\n' + body 
	}
	
	def CharSequence generateSlotsImpl(Iterable<Slot> slots, Set<String> imports) {
		'''
		«slots.map[generateSlotImpl(imports)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateSlotImpl(Slot slot, Set<String> imports) {
		val entity = slot.ownerEntity
		val isEnableDoc = entity.service.isEnableDoc
		val title = slot.title
		
		'''
		«IF isEnableDoc»
		@ApiModelProperty(notes = "«title»")
		«ENDIF»
		private «slot.resolveSlotAutocomplete(imports)» «slot.fieldName»«slot.resolveFieldInitializationValue»;
		'''
	}
	
	
	
}