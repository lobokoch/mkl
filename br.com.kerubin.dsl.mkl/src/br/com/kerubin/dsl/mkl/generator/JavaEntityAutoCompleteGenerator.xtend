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
		entities.forEach[generateAutoComplete]
	}
	
	def generateAutoComplete(Entity entity) {
		val slots = entity.slots.filter[it.isAutoCompleteResult]
		if (!slots.isEmpty) {
			val basePakage = clientGenSourceFolder
			val entityFile = basePakage + entity.packagePath + '/' + entity.toAutoCompleteName + '.java'
			generateFile(entityFile, entity.generateEntityAutoComplete(slots))
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
	
	
	
}