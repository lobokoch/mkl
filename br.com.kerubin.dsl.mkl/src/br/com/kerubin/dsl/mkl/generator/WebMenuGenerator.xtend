package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Entity

class WebMenuGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateMenu
	}
	
	protected def getFileExtension() {
		'.json'
	}
	
	def generateMenu() {
		val path = getWebMenuDir
		val filePath = path + 'menu' + getFileExtension()
		generateFile(filePath, doGenerateMenu)
	}
	
	protected def CharSequence doGenerateMenu() {
		service.domainModel
		val domainLabel = if (service.domainModel.hasLabel) service.domainModel.label else service.domain.toCamelCase
		val serviceLabel = if (service.hasLabel) service.label else service.name.toCamelCase
		
		'''
		{
			label: '«domainLabel»',
			icon: 'pi pi-pw',
			items: [
				
				{
					label: '«serviceLabel»',
					icon: 'pi pi-fw ',
					items: [
						«generateEntitiesMenuItems»
					]
				}
				
			]
		}
		'''
	}
	
	private def CharSequence generateEntitiesMenuItems() {
		'''
		«entities.filter[!it.externalEntity].map[generateEntityMenuItem].join(', \r\n')»
		'''
	}
	
	private def CharSequence generateEntityMenuItem(Entity entity) {
		'''{ label: '«entity.labelValue»', icon: 'pi pi-fw', routerLink: '/«entity.toWebName»' }'''
	}
	
	
}