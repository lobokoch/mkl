package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntityAutoComplete extends GeneratorExecutor implements IGeneratorExecutor {
	
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
			val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityAutoCompleteName + '.java'
			generateFile(entityFile, entity.generateEntityAutoComplete(slots))
		}
	}
	
	def CharSequence generateEntityAutoComplete(Entity entity, Iterable<Slot> slots) {	
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		public interface «entity.toEntityAutoCompleteName» {
		
			«slots.generateGetters»
		
		}
		'''
		package + /*imports +*/ body 
	}
	
	def CharSequence generateGetters(Iterable<Slot> slots) {
		'''
		«slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		'''
		«slot.toJavaTypeDTO» get«slot.name.toFirstUpper»();
		'''
	}
	
}