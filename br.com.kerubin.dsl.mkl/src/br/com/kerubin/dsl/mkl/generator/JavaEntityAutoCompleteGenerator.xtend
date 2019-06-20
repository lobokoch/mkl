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
		val slots = entity.slots.filter[it.isAutoCompleteResult]
		if (!slots.isEmpty) {
			val basePakage = clientGenSourceFolder // CLIENT
			val entityFile = basePakage + entity.packagePath + '/' + entity.toAutoCompleteName + '.java'
			generateFile(entityFile, entity.generateEntityAutoComplete(slots))
		}
	}
	
	def generateAutoCompleteImpl(Entity entity) {
		val slots = entity.slots.filter[it.isAutoCompleteResult]
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
		
		}
		'''
		package + imports.join('\r\n') + '\r\n' + body 
	}
	
	def CharSequence generateGetters(Iterable<Slot> slots, Set<String> imports) {
		'''
		«slots.map[generateGetter(imports)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot, Set<String> imports) {
		'''
		«slot.resolveSlotAutocomplete(imports)» get«slot.name.toFirstUpper»();
		'''
	}
	
	///// IMPL ***************
	def CharSequence generateEntityAutoCompleteImpl(Entity entity, Iterable<Slot> slots) {
		
		val imports = newLinkedHashSet
		
		imports.add('import lombok.Getter;')
		imports.add('import lombok.Setter;')
		
		val classNameImpl = entity.toAutoCompleteImplName
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
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
		'''
		private «slot.resolveSlotAutocomplete(imports)» «slot.fieldName»«slot.resolveFieldInitializationValue»;
		'''
	}
	
	
	
}