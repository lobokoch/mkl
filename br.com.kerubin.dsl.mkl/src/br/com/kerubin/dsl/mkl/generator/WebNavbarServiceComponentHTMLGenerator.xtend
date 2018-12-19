package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebNavbarServiceComponentHTMLGenerator extends WebNavbarComponentHTMLGenerator {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override getWebNavbarFileDir() {
		service.webServiceNavbarPath
	}
	
	override CharSequence generateMenuItems() {
		'''
		<!-- Begin «service.domain».«service.name» menu itens -->
		«generateEntitiesMenuItems»
		<!-- End «service.domain».«service.name» menu itens -->
		
		'''
	}
	
	private def CharSequence generateEntitiesMenuItems() {
		'''
		«entities.map[generateEntityMenuItem].join»
		'''
	}
	
	private def CharSequence generateEntityMenuItem(Entity entity) {
		'''
		<li class="navbar-menuitem" routerLinkActive="active"><a routerLink="/«entity.toWebName»">«entity.labelValue»</a></li>
		'''
	}
	
}