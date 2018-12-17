package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Service

interface ServiceBooster {
	
	def void augmentService(Service service)
	
}